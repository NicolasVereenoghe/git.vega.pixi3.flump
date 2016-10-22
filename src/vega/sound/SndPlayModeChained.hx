package vega.sound;

/**
 * on lance un son dès qu'un autre s'est arrêté
 * @author	nico
 */
class SndPlayModeChained extends SndPlayMode {
	/** pattern de recherche d'identifiants de son à vérifier la fin de lecture avant de lancer notre son ; laisser null pour tout vérifier */
	var _subId							: String							= null;
	
	/**
	 * @inheritDoc
	 * @param		pSubId	pattern de recherche d'identifiants de son à vérifier la fin de lecture avant de lancer notre son ; laisser null pour tout vérifier
	 */
	public function new( pSubId : String = null) {
		super();
		
		_subId = pSubId;
	}
	
	/**
	 * on récupère la pattern de recherche d'identifiants de son à vérifier la fin de lecture avant de lancer notre son
	 * @return	pattern de recherche, ou null pour désigner tous les sons
	 */
	public function getSubId() : String { return _subId; }
}