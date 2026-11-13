(function() {
  var mod = window.Module = window.Module || {};
  mod.canvas = mod.canvas || document.querySelector('canvas');
  mod.setStatus = mod.setStatus || function() {};
  mod.preRun = mod.preRun || [];
  mod.postRun = mod.postRun || [];

  function sinalizarPronto() {
    mod.canvas = mod.canvas || document.querySelector('canvas');
    mod.calledRun = true;
    mod.runtimeInitialized = true;
    window.__jogoRodando = true;
    window.calledMain = true;
    if (typeof mod.onRuntimeInitialized === 'function') {
      try { mod.onRuntimeInitialized(); } catch (e) {}
    }
    if (Array.isArray(mod.postRun)) {
      while (mod.postRun.length) {
        try { mod.postRun.shift()(); } catch (e) {}
      }
    }
    try { window.dispatchEvent(new Event('resize')); } catch (e) {}
  }

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    setTimeout(sinalizarPronto, 300);
  } else {
    window.addEventListener('DOMContentLoaded', function() { setTimeout(sinalizarPronto, 300); });
    window.addEventListener('load', function() { setTimeout(sinalizarPronto, 100); });
  }
})();
