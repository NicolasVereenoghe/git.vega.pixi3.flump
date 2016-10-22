package vega.loader.file;
import howler.Howl;
import vega.shell.ApplicationMatchSize;
import vega.sound.SndDesc;
import vega.sound.SndMgr;

/**
 * chargement d'un fichier de son Howl
 * 
 * @author nico
 */
class LoadingFileHowl extends LoadingFile {
	/** nombre max de reloads avant de laisser tomber */
	public static inline var RELOAD_MAX			: Int					= 20;
	
	/** descripteur de son chargé */
	var desc									: SndDesc				= null;
	
	/** compteur de tentatives de loading */
	var ctrReload								: Int					= 0;
	
	/**
	 * construction de chargement de son Howl ; on désactive la lecture automatique et le préchargement automatique dans les options des descripteur de son
	 * @param	pSndDesc
	 */
	public function new( pSndDesc : SndDesc) {
		desc	= pSndDesc;
		
		super( null);
	}
	
	/** @inheritDoc */
	override public function getId() : String { return desc.getId(); }
	
	/** @inheritDoc */
	override public function getLoadedContent( pId : String = null) : Dynamic { return desc.getHowl(); }
	
	/** @inheritDoc */
	override public function isIMG() : Bool { return false; }
	
	/** @inheritDoc */
	override function doLoad() : Void {
		var lOptions	: HowlOptions	= desc.getOptions();
		
		lOptions.autoplay		= false;
		lOptions.preload		= false;
		
		desc.regHowl( new Howl( desc.getOptions()));
		
		desc.getHowl().on( "load", onLoadComplete);
		desc.getHowl().on( "loaderror", onLoadError);
		
		desc.getHowl().load();
	}
	
	/** @inheritDoc */
	override function buildLoader() : Void { }
	
	/** @inheritDoc */
	override function freeLoader() : Void { desc = null; }
	
	/** @inheritDoc */
	override function removeLoaderListener() : Void {
		desc.getHowl().off( "load", onLoadComplete);
		desc.getHowl().off( "loaderror", onLoadError);
	}
	
	/** @inheritDoc */
	override function onLoadComplete() : Void {
		ApplicationMatchSize.instance.traceDebug( "INFO : LoadingFileHowl::onLoadComplete  : " + desc.getId());
		
		removeLoaderListener();
		
		vegaLoader.onCurFileLoaded();
		
		vegaLoader = null;
		
		SndMgr.getInstance().addSndDesc( desc);
	}
	
	/**
	 * capture d'erreur de chargement, on essaye de recharger ; si trop de tentatives, on skip
	 */
	function onLoadError() : Void {
		if( ctrReload++ < RELOAD_MAX){
			ApplicationMatchSize.instance.traceDebug( "ERROR : LoadingFileHowl::onLoadError : " + desc.getId() + " : retry " + ctrReload);
			
			desc.getHowl().load();
		}else {
			ApplicationMatchSize.instance.traceDebug( "ERROR : LoadingFileHowl::onLoadError : " + desc.getId() + " : skip !");
			
			removeLoaderListener();
			
			vegaLoader.onCurFileLoaded( false);
			
			vegaLoader = null;
			
			SndMgr.getInstance().addSndDesc( desc);
			
			free();
		}
	}
}