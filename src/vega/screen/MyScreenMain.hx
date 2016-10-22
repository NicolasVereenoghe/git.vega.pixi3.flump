package vega.screen;
import pixi.core.display.DisplayObject;
import pixi.flump.Movie;
import pixi.interaction.EventTarget;
import vega.local.LocalMgr;
import vega.utils.UtilsFlump;
import vega.utils.UtilsPixi;

/**
 * ...
 * @author nico
 */
class MyScreenMain extends MyScreen {
	var hit					: DisplayObject;
	var startBt				: DisplayObject;
	
	public function new() {
		super();
		
		ASSET_ID	= "screenMain";
	}
	
	override public function destroy() : Void {
		if ( asset != null) LocalMgr.instance.recursiveFreeLocalTxt( cast asset.getContent());
		
		if ( startBt != null){
			UtilsPixi.unsetQuickBt( startBt);
			startBt = null;
		}
		
		if ( hit != null){
			UtilsPixi.unsetQuickBt( hit);
			hit = null;
		}
		
		super.destroy();
	}
	
	override function buildContent() : Void {
		super.buildContent();
		
		if ( asset != null){
			if( UtilsFlump.getLayerWithPrefixInMovie( "hit", cast asset.getContent()) != null){
				hit = cast( asset.getContent(), Movie).getLayer( "hit");
				hit.alpha = 0;
				
				UtilsPixi.setQuickBt( hit, onBtStart);
			}
			
			if ( UtilsFlump.getLayerWithPrefixInMovie( "start", cast asset.getContent()) != null){
				startBt = cast( asset.getContent(), Movie).getLayer( "start");
				
				UtilsPixi.setQuickBt( startBt, onBtStart);
				
				if ( hit != null) hit.buttonMode = false;
			}
			
			LocalMgr.instance.recursiveSetLocalTxt( cast asset.getContent());
		}
	}
	
	override function launchAfterInit() : Void { shell.onScreenReady( this); }
	
	function onBtStart( pE : EventTarget) : Void {
		shell.onScreenClose( this);
		
		setModeFadeOut();
		
		//pE.stopPropagation();
	}
}