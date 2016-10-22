package vega.sound;
import vega.shell.ApplicationMatchSize;
import vega.shell.VegaFramer;

/**
 * instance de son ( descripteur de canal sonore ouvert)
 * @author nico
 */
class SndInstance {
	/** délai max d'attente en ms pour reprise de lecture une fois le chargement effectué */
	var PLAY_DELAI_MAX					: Float							= 1500;
	
	/** ref sur la piste sonore en charge de cette instance de son */
	var track							: SndTrack						= null;
	/** id de canal sonore de son ; -1 si pas encore défini */
	var chan							: Int							= -1;
	/** mode de lecture ; null si aucun de particulier */
	var mode							: SndPlayMode					= null;
	
	/** timestamp en ms de demande de lancement avant chargement ; < 0 si pas défini */
	var playTimestamp					: Float							= -1;
	
	/** itération de frame ; null si pas d'itération en cours */
	var doMode							: Void->Void					= null;
	
	/**
	 * construction
	 * @param	pTrack	piste sonore en charge de cette instance de son
	 */
	public function new( pTrack : SndTrack) {
		track	= pTrack;
		
		VegaFramer.getInstance().addIterator( onFrame);
	}
	
	/**
	 * on effectue une lecture simple
	 * @param	pMode	mode de lecture du son, laisser null pour une lecture par défaut
	 */
	public function play( pMode : SndPlayMode = null) : Void {
		mode	= pMode;
		
		if ( ! regChainedTracks()) tryUnloadedTrackOpenChan();
	}
	
	/**
	 * on lance une lecture virtuelle d'un canal invalide
	 * @param	pMode	mode de lecture du son, laisser null pour une lecture par défaut
	 */
	public function playInvalid( pMode : SndPlayMode = null) : Void {
		ApplicationMatchSize.instance.traceDebug( "WARNING : SndInstance::playInvalid : " + track.getDesc().getId());
		
		mode	= pMode;
		
		regChainedTracks();
		
		setModeOpenChanInvalid();
	}
	
	/**
	 * on effectue l'enregistrement des écouteurs de son chainés si le mode de lecture le requiert
	 * @return	true si il y a eu chaînage, false  sinon
	 */
	function regChainedTracks() : Bool {
		var lTracks	: Array<SndTrack>;
		var lTrack	: SndTrack;
		
		if ( Std.is( mode, SndPlayModeChained)){
			if ( SndMgr.getInstance().isPlaying( cast( mode, SndPlayModeChained).getSubId())){
				lTracks = SndMgr.getInstance().getSndTracks( cast( mode, SndPlayModeChained).getSubId());
				
				for ( lTrack in lTracks){
					if ( lTrack.isPlaying()) lTrack.addEndListener( onSndChainEnd);
				}
				
				return true;
			}
		}
		
		return false;
	}
	
	/**
	 * itération de frame
	 * @param	pDT	dt en ms
	 */
	function onFrame( pDT : Float) : Void { if ( doMode != null) doMode(); }
	
	/**
	 * on essaye d'ouvrir un canal qui est potentiellement pas chargé ; si c'est le cas on essaye de le faire tourner virtuellement
	 */
	function tryUnloadedTrackOpenChan() : Void {
		if ( ! track.getDesc().getIsLoaded()) setModeOpenChanInvalid();
		else openChan();
	}
	
	/**
	 * on passe en mode itération d'un canal pas prêt ; on surveille quand il le sera, on le stope si trop tard
	 */
	function setModeOpenChanInvalid() : Void {
		playTimestamp = Date.now().getTime();
		
		doMode = doModeOpenChanInvalid;
	}
	
	/**
	 * on agit en mode itération d'un canal pas prêt ; on surveille quand il le sera, on le stope si trop tard
	 */
	function doModeOpenChanInvalid() : Void {
		if ( track.getDesc().getIsLoaded() && SndMgr.getInstance().isUnlocked()) checkTimestampPlay();
		else checkTimestampStop();
	}
	
	/**
	 * on stope le canal
	 */
	public function stop() : Void {
		var lTracks	: Array<SndTrack>;
		var lTrack	: SndTrack;
		
		if ( chan >= 0){
			track.getDesc().getHowl().stop( chan);
			chan = -1;
		}
		
		if ( Std.is( mode, SndPlayModeChained)) {
			lTracks = SndMgr.getInstance().getSndTracks( cast( mode, SndPlayModeChained).getSubId());
			
			for ( lTrack in lTracks) lTrack.remEndListener( onSndChainEnd);
		}
		
		onSndEnd();
	}
	
	/**
	 * on vérifie le timestamp et si on est hors délai on stope
	 */
	public function checkTimestampStop() : Void {
		if ( playTimestamp > 0){
			if( ( ! track.getDesc().getOptions().loop) && Date.now().getTime() - playTimestamp > PLAY_DELAI_MAX) {
				ApplicationMatchSize.instance.traceDebug( "WARNING : SndInstance::checkTimestampStop : too late, stop : " + track.getDesc().getId());
				
				stop();
			}
		}
	}
	
	/**
	 * on vérifie le timestamp et si on est toujours dans les délais, on lance la lecture, sinon on stope
	 */
	public function checkTimestampPlay() : Void {
		if ( playTimestamp > 0){
			if( track.getDesc().getOptions().loop || Date.now().getTime() - playTimestamp <= PLAY_DELAI_MAX) {
				ApplicationMatchSize.instance.traceDebug( "INFO : SndInstance::checkTimestampPlay : loaded, resume play : " + track.getDesc().getId());
				
				if ( Std.is( mode, SndPlayModeChained)) onSndChainEnd();
				else openChan();
			}else {
				ApplicationMatchSize.instance.traceDebug( "WARNING : SndInstance::checkTimestampPlay : loaded, too late, stop : " + track.getDesc().getId());
				
				stop();
			}
		}
	}
	
	/**
	 * on ouvre un canal de lecture
	 */
	function openChan() : Void {
		doMode = null;
		
		if( ! SndMgr.getInstance().isUnlocked()) ApplicationMatchSize.instance.traceDebug( "WARNING : SndInstance::openChan : unlocker ? : " + track.getDesc().getId());
		
		chan = track.getDesc().getHowl().play();
		
		track.getDesc().getHowl().on( "end", onSndEnd, chan);
		
		if ( chan >= 0){
			ApplicationMatchSize.instance.traceDebug( "INFO : SndInstance::openChan : " + track.getDesc().getId() + " : " + chan);
			playTimestamp = -1;
		}else ApplicationMatchSize.instance.traceDebug( "ERROR : SndInstance::openChan : " + track.getDesc().getId() + " : " + chan);
	}
	
	/**
	 * on capture la fin de lecture du canal sonore ; si pas de boucle, on détruit ce canal
	 */
	function onSndEnd() : Void {
		if ( chan >= 0) {
			if ( track.getDesc().getOptions().loop){
				if ( track.getDesc().getHowl().playing( chan)) ApplicationMatchSize.instance.traceDebug( "INFO : SndInstance::onSndEnd : loop " + track.getDesc().getId() + " : " + chan);
				else{
					ApplicationMatchSize.instance.traceDebug( "WARNING : SndInstance::onSndEnd : broken loop, restart : " + track.getDesc().getId() + " : " + chan);
					
					chan = track.getDesc().getHowl().play();
				}
				
				return;
			}
			
			track.getDesc().getHowl().off( "end", onSndEnd, chan);
		}
		
		doMode = null;
		VegaFramer.getInstance().remIterator( onFrame);
		
		ApplicationMatchSize.instance.traceDebug( "INFO : SndInstance::onSndEnd : " + track.getDesc().getId() + " : " + chan);
		
		track.onChanStop( this);
	}
	
	/**
	 * on capture la fin de lecture d'un canal chainé
	 */
	function onSndChainEnd() : Void {
		var lTracks	: Array<SndTrack>;
		var lTrack	: SndTrack;
		
		if ( track.getDesc().getIsLoaded() && SndMgr.getInstance().isUnlocked() && ! SndMgr.getInstance().isPlaying( cast( mode, SndPlayModeChained).getSubId())) {
			lTracks = SndMgr.getInstance().getSndTracks( cast( mode, SndPlayModeChained).getSubId());
			
			for ( lTrack in lTracks) lTrack.remEndListener( onSndChainEnd);
			
			ApplicationMatchSize.instance.traceDebug( "INFO : SndInstance::onSndChainEnd : play " + track.getDesc().getId());
			
			openChan();
		}
	}
}