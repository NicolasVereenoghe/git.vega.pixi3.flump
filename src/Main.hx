package;

import js.Browser;
import pixi.core.display.Container;
import pixi.flump.Movie;
import pixi.flump.Parser;
import pixi.loaders.Loader;

import vega.shell.ApplicationMatchSize;

/**
 * ...
 * @author nico
 */
class Main extends ApplicationMatchSize {
	var loader	: Loader;
	
	static function main() { new Main(); }
	
	public function new() {
		super();
		
		loader	= new Loader();
		loader.add( "", "assets/assetsTest/library.json?v=4");
		loader.after( Parser.parse( 1));
		loader.load( onLoadComplete);
		
	}
	
	function onLoadComplete() : Void {
		loader.removeAllListeners();
		
		getContent().addChild( new Movie( "test"));
		
		onUpdate = doUpdate;
	}
	
	function doUpdate( pT : Float) : Void {
		var lCont	: Container	= cast( getContent().getChildAt( 0), Movie).getLayer( "cube");
		
		lCont.y = 150 * Math.cos( Math.PI * 2 * pT / 1000) + 100;
	}
}