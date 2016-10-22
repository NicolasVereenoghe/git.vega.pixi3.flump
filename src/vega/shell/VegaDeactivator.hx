package vega.shell;
import js.Browser;
import js.html.VisibilityState;
import vega.sound.SndMgr;

/**
 * ...
 * @author ...
 */
class VegaDeactivator {
	var TIMEOUT_DELAY							: Int									= 120000;//600000;
	
	static var instance							: VegaDeactivator						= null;
	
	var isActive								: Bool									= true;
	
	var timeoutId								: Int;
	var timeoutTimeStamp						: Float									= -1;
	
	public static function getInstance() : VegaDeactivator {
		if ( instance == null) instance = new VegaDeactivator();
		
		return instance;
	}
	
	function new() {
		if ( Browser.supported){
			// ne marche pas partout (android)
			Browser.window.onfocus	= activate;
			Browser.window.onblur	= deactivate;
			
			Browser.document.addEventListener( "visibilitychange", onVChange);
			
			if ( ( ! isSystemActive()) || ! Browser.document.hasFocus()) deactivate( false);
			
			onFocus();
		} else ApplicationMatchSize.instance.traceDebug( "ERROR : VegaDeactivator::VegaDeactivator : no browser, ignore deactivate ...");
	}
	
	function onVChange() : Void {
		if ( isSystemActive()) activate();
		else deactivate();
	}
	
	function isSystemActive() : Bool { return Browser.document.visibilityState == VisibilityState.VISIBLE; }
	
	function deactivate( pSetTimeout : Bool = true) : Void {
		if ( ! isActive) return;
		
		ApplicationMatchSize.instance.traceDebug( "INFO : VegaDeactivator::deactivate");
		
		isActive = false;
		
		VegaFramer.getInstance().switchPause( true);
		
		ApplicationMatchSize.instance.forceFPS( 1);
		ApplicationMatchSize.instance.pauseRendering();
		
		SndMgr.getInstance().switchMute( true);
		
		if( pSetTimeout){
			timeoutTimeStamp	= Date.now().getTime();
			timeoutId			= Browser.window.setTimeout( onTimeout, TIMEOUT_DELAY);
		}else{
			timeoutTimeStamp	= -1;
		}
		
		ApplicationMatchSize.instance.canvas.addEventListener( "mousedown", onFocus);
		ApplicationMatchSize.instance.canvas.addEventListener( "mousemove", onFocus);
		ApplicationMatchSize.instance.canvas.addEventListener( "touchstart", onFocus);
		ApplicationMatchSize.instance.canvas.addEventListener( "touchmove", onFocus);
	}
	
	function activate() : Void {
		if ( isActive) return;
		
		if ( timeoutTimeStamp >= 0 && Date.now().getTime() - timeoutTimeStamp >= TIMEOUT_DELAY) onTimeout()
		else{		
			ApplicationMatchSize.instance.traceDebug( "INFO : VegaDeactivator::activate");
			
			isActive = true;
			
			VegaFramer.getInstance().switchPause( false);
			
			ApplicationMatchSize.instance.restaureFPS();
			ApplicationMatchSize.instance.resumeRendering();
			ApplicationMatchSize.instance.refreshRender();
			
			SndMgr.getInstance().switchMute( false);
			
			if ( GlobalPointer.instance != null) GlobalPointer.instance.flush();
			
			VegaOrient.getInstance().flush();
			
			if ( timeoutTimeStamp >= 0) Browser.window.clearTimeout( timeoutId);
			
			ApplicationMatchSize.instance.canvas.removeEventListener( "mousedown", onFocus);
			ApplicationMatchSize.instance.canvas.removeEventListener( "mousemove", onFocus);
			ApplicationMatchSize.instance.canvas.removeEventListener( "touchstart", onFocus);
			ApplicationMatchSize.instance.canvas.removeEventListener( "touchmove", onFocus);
		}
	}
	
	function onTimeout() : Void { ApplicationMatchSize.instance.reload(); }
	
	function onFocus() : Void { Browser.window.focus(); }
}