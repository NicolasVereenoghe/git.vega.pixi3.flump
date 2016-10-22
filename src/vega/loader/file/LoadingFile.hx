package vega.loader.file;
import pixi.loaders.Loader;
import vega.loader.VegaLoader;
import vega.shell.ApplicationMatchSize;

/**
 * ...
 * @author nico
 */
class LoadingFile {
	static var VERSION_PARAM				: String		= "v";
	
	var _file								: MyFile;
	var vegaLoader							: VegaLoader;
	
	var loader								: Loader;
	
	public function new( pFile : MyFile) {
		_file = pFile;
		
		buildLoader();
	}
	
	public function free() : Void {
		if ( vegaLoader != null) removeLoaderListener();
		
		vegaLoader	= null;
		_file		= null;
		
		freeLoader();
	}
	
	public function getId() : String { return _file.getId(); }
	
	public function load( pLoader : VegaLoader) {
		vegaLoader		= pLoader;
		
		doLoad();
	}
	
	public function getLoadedContent( pId : String = null) : Dynamic {
		if ( loader != null && ! loader.loading && loader.progress > 0){
			return Reflect.getProperty( loader.resources, _file.getId()).data;
		}else return null;
	}
	
	public function isIMG() : Bool { return Reflect.getProperty( loader.resources, _file.getId()).isImage; }
	
	public function getUrl() : String { return Reflect.getProperty( loader.resources, _file.getId()).url; }
	
	function buildLoader() : Void {
		loader	= new Loader();
		loader.add( _file.getId(), getUrlRequest());
	}
	
	function freeLoader() : Void {
		if( loader != null){
			loader.reset();
			
			loader = null;
		}
	}
	
	function doLoad() : Void { loader.load( onLoadComplete); }
	
	function removeLoaderListener() : Void {
		loader.removeAllListeners();
	}
	
	function onLoadComplete() : Void {
		if( Reflect.getProperty( loader.resources, _file.getId()).error == null){
			trace( Reflect.getProperty( loader.resources, _file.getId()));
			
			removeLoaderListener();
			
			vegaLoader.onCurFileLoaded();
			
			vegaLoader = null;
		}else{
			ApplicationMatchSize.instance.traceDebug( "ERROR : LoadingFile::onLoadComplete : " + _file.getId() + " : " + Reflect.getProperty( loader.resources, _file.getId()).error);
			
			loader.reset();
			loader.add( _file.getId(), getUrlRequest());
			loader.load( onLoadComplete);
		}
	}
	
	function getUrlRequest() : String {
		var lName		: String	= _file.getName();
		var lPath		: String	= _file.getPath() != null ? _file.getPath() : "";
		var lUrl		: String;
		
		if( lName.indexOf( "://") != -1) lUrl = lName;
		else lUrl = lPath + lName;
		
		lUrl = addVersionToUrl( lUrl, getVersionUrl( _file));
		
		return lUrl;
	}
	
	public static function getVersionUrl( pFile : MyFile) : String {
		var lVer	: String	= pFile.getVersion();
		
		if ( lVer != null){
			if ( lVer != MyFile.NO_VERSION){
				if ( lVer == MyFile.VERSION_NO_CACHE) return Std.string( Date.now().getTime());
				else return lVer;
			}
		}
		
		return "";
	}
	
	public static function addVersionToUrl( pUrl : String, pVersion : String) : String {
		if( pVersion != null && pVersion != ""){
			if( pUrl.indexOf( "?") != -1) return pUrl + "&" + VERSION_PARAM + "=" + pVersion;
			else return pUrl + "?" + VERSION_PARAM + "=" + pVersion;
		}
		
		return pUrl;
	}
}