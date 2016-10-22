package vega.loader.file;
import pixi.core.textures.Texture;
import pixi.flump.Resource;
import pixi.flump.Parser;

/**
 * ...
 * @author nico
 */
class LoadingFileFlump extends LoadingFile {
	public function new( pFile : MyFile) { super( pFile); }
	
	override public function free() : Void {
		Resource.destroy( getId());
		
		super.free();
	}
	
	override function buildLoader() : Void {
		super.buildLoader();
		
		loader.after( Parser.parse( 1, LoadingFile.getVersionUrl( _file)));
	}
}