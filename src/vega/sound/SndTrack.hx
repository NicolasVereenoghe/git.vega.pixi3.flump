package vega.sound;
import vega.loader.VegaLoaderMgr;
import vega.loader.file.LoadingFileHowl;
import vega.shell.ApplicationMatchSize;

/**
 * une piste de son
 * @author nico
 */
class SndTrack {
	/** descripteur du son */
	var _desc								: SndDesc								= null;
	
	/** pile de canaux sonores ouverts */
	var channels							: Array<SndInstance>					= null;
	
	/** pile d'écouteurs de fin de lecture de canaux */
	var endListeners						: Array<Void->Void>						= null;
	
	/** flag indiquant si la piste est en cours de chargement */
	var isLoading							: Bool									= false;
	
	/**
	 * construction de la piste
	 * @param	pDesc	descripteur de son de cette piste
	 * @param	pDoLoad	true pour faire le chargement si le son n'est pas tagué "loaded", sinon laisser false pour juste ajouter un descripteur ; /!\ : sur android, un son qui vient d'être chargé peut toujours être tagué "unloaded", risque de tout casser si on le recharge de suite
	 */
	public function new( pDesc : SndDesc, pDoLoad : Bool = false) {
		_desc							= pDesc;
		channels						= new Array<SndInstance>();
		endListeners					= new Array<Void->Void>();
		
		if ( pDoLoad && ! _desc.getIsLoaded()) doLoad();
	}
	
	/**
	 * on libère la mémoire occupée par cette piste
	 */
	public function destroy() : Void {
		VegaLoaderMgr.getInstance().freeLoadedFileMem( _desc.getFileResId());
		
		stop();
		
		if ( _desc.getIsLoaded()) _desc.getHowl().unload();
		if ( isLoading) remLoadListener();
		
		_desc.destroy();
		
		channels = null;
		endListeners = null;
		_desc = null;
	}
	
	/**
	 * on récupère le descripteur de son de la piste
	 * @return	descripteur de son
	 */
	public function getDesc() : SndDesc { return _desc; }
	
	/**
	 * on joue une occurence de son de la piste
	 * @param	pMode			mode de lecture du son, laisser null pour une lecture par défaut
	 * @param	pCheckInvalid	true pour demander un mode de lecture dans lequel on contrôle la validité du composant son avant d'ouvrir le canal
	 */
	public function play( pMode : SndPlayMode = null, pCheckInvalid : Bool = false) : Void { addSndInstance( pMode, pCheckInvalid); }
	
	//playInvalidLoop
	
	/**
	 * on arrête toutes les occurences de sons de cette piste
	 */
	public function stop() : Void {
		var lI		: Int		= channels.length - 1;
		
		while ( lI >= 0) channels[ lI--].stop();
	}
	
	/**
	 * on vérifie si au moins un son de la piste est en train d'être joué
	 * @return	true si un son est en train d'être joué, false sinon
	 */
	public function isPlaying() : Bool {
		//var lSnd	: SndInstance;
		
		//for ( lSnd in channels) lSnd.checkTimestampStop();
		
		return channels.length > 0;
	}
	
	/**
	 * on est notifié de l'arrêt d'un canal de la piste
	 * @param	pChan	canal qui s'est arrêté et qu'on libère
	 */
	public function onChanStop( pChan : SndInstance) : Void {
		var lI			: Int;
		
		channels.remove( pChan);
		
		if ( ! isPlaying()){
			lI = endListeners.length - 1;
			
			while ( lI >= 0) endListeners[ lI]();
		}
	}
	
	/**
	 * on ajoute un écouteur de fin de lecture d'un canal
	 * @param	pListener	méthode de call back à appeler en fin de lecture d'une instance de canal sonore
	 */
	public function addEndListener( pListener : Void -> Void) : Void { endListeners.push( pListener); }
	
	/**
	 * on retire un écouteur de fin de lecture d'un canal
	 * @param	pListener	méthode de call back à appeler en fin de lecture d'une instance de canal sonore
	 */
	public function remEndListener( pListener : Void -> Void) : Void { endListeners.remove( pListener); }
	
	/**
	 * on lance une instance de son
	 * @param	pMode			mode de lecture du son, laisser null pour une lecture par défaut
	 * @param	pCheckInvalid	true pour demander un mode de lecture dans lequel on contrôle la validité du composant son avec d'ouvrir le canal
	 */
	function addSndInstance( pMode : SndPlayMode = null, pCheckInvalid : Bool = false) : Void {
		var lSnd	: SndInstance;
		
		lSnd = new SndInstance( this);
		channels.push( lSnd);
		
		if ( pCheckInvalid) lSnd.playInvalid( pMode);
		else lSnd.play( pMode);
		
		if ( ! ( _desc.getIsLoaded() || isLoading)) {
			doLoad();
		}
	}
	
	/**
	 * on lance le chargement du son howl
	 */
	function doLoad() : Void {
		ApplicationMatchSize.instance.traceDebug( "INFO : SndTrack::doLoad : " + _desc.getId() + " : " + _desc.getHowl().state());
		
		isLoading = true;
		_desc.getHowl().load();
		
		_desc.getHowl().on( "load", onTrackLoaded);
		_desc.getHowl().on( "loaderror", onTrackLoadError);
	}
	
	/**
	 * on retire les listeners de loading
	 */
	function remLoadListener() : Void {
		_desc.getHowl().off( "load", onTrackLoaded);
		_desc.getHowl().off( "loaderror", onTrackLoadError);
	}
	
	/**
	 * on capture la fin de chargement de la piste
	 */
	function onTrackLoaded() : Void {
		var lI		: Int			= channels.length - 1;
		
		ApplicationMatchSize.instance.traceDebug( "INFO : SndTrack::onTrackLoaded : " + _desc.getId());
		VegaLoaderMgr.getInstance().regLoadedFile( new LoadingFileHowl( _desc));
		
		remLoadListener();
		
		isLoading		= false;
		
		while ( lI >= 0) channels[ lI--].checkTimestampPlay();
	}
	
	/**
	 * on capture une erreur de chargement de la piste
	 */
	function onTrackLoadError() : Void {
		var lI		: Int			= channels.length - 1;
		
		ApplicationMatchSize.instance.traceDebug( "ERROR : SndTrack::onTrackLoadError : " + _desc.getId());
		remLoadListener();
		
		isLoading = false;
		
		while ( lI >= 0) channels[ lI].stop();
	}
}