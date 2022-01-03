/*
 * Troy's HBC-56 Emulator - Web front-end
 *
 * Copyright (c) 2021 Troy Schrapel
 *
 * This code is licensed under the MIT license
 *
 * https://github.com/visrealm/hbc-56/emulator
 *
 */

var statusElement = document.getElementById('status');
var progressElement = document.getElementById('progress');
var spinnerElement = document.getElementById('spinner');

var Module = {
    preRun: [],
    postRun: [],
    print: (function()
    {
        var element = document.getElementById('output');
        if (element) element.value = ''; // clear browser cache
        return function(text)
        {
            if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(' ');
            // These replacements are necessary if you render to raw HTML
            //text = text.replace(/&/g, "&amp;");
            //text = text.replace(/</g, "&lt;");
            //text = text.replace(/>/g, "&gt;");
            //text = text.replace('\n', '<br>', 'g');
            console.log(text);
            if (element)
            {
                element.value += text + "\n";
                element.scrollTop = element.scrollHeight; // focus on bottom
            }
        };
    })(),
    canvas: (function()
    {
        var canvas = document.getElementById('canvas');

        // As a default initial behavior, pop up an alert when webgl context is lost. To make your
        // application robust, you may want to override this behavior before shipping!
        // See http://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
        canvas.addEventListener("webglcontextlost", function(e)
        {
            alert('WebGL context lost. You will need to reload the page.');
            e.preventDefault();
        }, false);

        return canvas;
    })(),
    setStatus: function(text)
    {
        if (!Module.setStatus.last) Module.setStatus.last = {
            time: Date.now(),
            text: ''
        };
        if (text === Module.setStatus.last.text) return;
        var m = text.match(/([^(]+)\((\d+(\.\d+)?)\/(\d+)\)/);
        var now = Date.now();
        if (m && now - Module.setStatus.last.time < 30) return; // if this is a progress update, skip it if too soon
        Module.setStatus.last.time = now;
        Module.setStatus.last.text = text;
        if (m)
        {
            text = m[1];
            progressElement.value = parseInt(m[2]) * 100;
            progressElement.max = parseInt(m[4]) * 100;
            progressElement.hidden = false;
            spinnerElement.hidden = false;
        }
        else
        {
            progressElement.value = null;
            progressElement.max = null;
            progressElement.hidden = true;
            if (!text) spinnerElement.style.display = 'none';
        }
        statusElement.innerHTML = text;
    },
    totalDependencies: 0,
    monitorRunDependencies: function(left)
    {
        this.totalDependencies = Math.max(this.totalDependencies, left);
        Module.setStatus(left ? 'Preparing... (' + (this.totalDependencies - left) + '/' + this.totalDependencies + ')' : 'All downloads complete.');
    }
};
Module.setStatus('Downloading...');
window.onerror = function(event)
{
    // TODO: do not warn on ok events like simulating an infinite loop or exitStatus
    Module.setStatus('Exception thrown, see JavaScript console');
    spinnerElement.style.display = 'none';
    Module.setStatus = function(text)
    {
        if (text) Module.printErr('[post-exception status] ' + text);
    };
};

var audioContext;

window.addEventListener('load', init, false);

function init()
{

    try
    {
        window.AudioContext = window.AudioContext || window.webkitAudioContext;
        audioContext = new AudioContext();
        console.log("AudioContext OK.")
    }
    catch (e)
    {
        console.log("AudioContext not supported on this Browser.")
    }
}


function toggleAudio()
{
    if (audioContext && audioContext.state != "running")
    {
        audioContext.resume().then(() =>
        {
            console.log("Resumed Audio.")
            Module.ccall("hbc56Audio", "void", ["int"], [1]);
        });
    }
    else if (audioContext && audioContext.state == "running")
    {
        audioContext.suspend().then(function()
        {
            console.log("Stopped Audio.")
            Module.ccall("hbc56Audio", "void", ["int"], [0]);
        });
    }
    canvas.focus();
}

function resetHbc56()
{
    Module.ccall("hbc56Reset", "void", ["void"], []);
}

function romDropHandler(event)
{
    event.preventDefault();

    if (event.dataTransfer.items)
    {
        // Use DataTransferItemList interface to access the file(s)
        for (var i = 0; i < event.dataTransfer.items.length; i++)
        {
            // If dropped items aren't files, reject them
            if (event.dataTransfer.items[i].kind === 'file')
            {
                var file = event.dataTransfer.items[i].getAsFile();
                if (file.name.endsWith(".o.lmap"))
                {
                    var filename = file.name.repeat(1);
                    console.log('Loading labels: ' + filename);

                    var reader = new FileReader();
                    reader.readAsText(event.dataTransfer.items[i].getAsFile());
                    reader.onload = function()
                    {
                        Module.ccall("hbc56LoadLabels", "void", ["string"], [reader.result]);
                        console.log('Loaded labels: ' + filename);
                    };
                }
                else if (file.name.endsWith(".o"))
                {
                    var filename2 = file.name.repeat(1);
                    console.log('Loading ROM: ' + filename2);
                    var reader2 = new FileReader();
                    reader2.readAsArrayBuffer(event.dataTransfer.items[i].getAsFile());
                    reader2.onload = function()
                    {
                        var bytes = new Uint8Array(reader2.result);
                        var result = Module.ccall("hbc56LoadRom", "int", ["array", "int"], [bytes, bytes.length]);
                        console.log(result);

                        if (result)
                        {
                            console.log('Loaded ROM: ' + filename2);
                        }
                        else
                        {
                            alert("Error loading ROM " + filename2);
                        }
                    };
                }
                else
                {
                    alert("Invalid file: '" + file.name + "'. Accepts .o or .o.lmap files only");
                }
            }
        }
    }
    else
    {
        // Use DataTransfer interface to access the file(s)
        for (var i = 0; i < event.dataTransfer.files.length; i++)
        {
            console.log('... file[' + i + '].name = ' + event.dataTransfer.files[i].name);
        }
    }
}

function romDragEnter(event)
{
    event.preventDefault();
}