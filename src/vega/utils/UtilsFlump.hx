package vega.utils;
import flump.library.Layer;
import flump.library.MovieSymbol;
import js.Browser;
import js.FullScreenApi;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.graphics.Graphics;
import pixi.core.math.Point;
import pixi.core.math.shapes.Rectangle;
import pixi.core.textures.Texture;
import pixi.flump.Movie;
import pixi.flump.Resource;
import pixi.flump.Sprite;
import pixi.interaction.EventTarget;
import vega.assets.AssetInstance;
import vega.assets.AssetsMgr;
import vega.shell.ApplicationMatchSize;
import vega.ui.MyButtonFlump;

/**
 * ...
 * @author nico
 */
@:access(pixi.flump.Resource)
@:access(pixi.flump.Movie)
class UtilsFlump {
	/** affix de clone de layer */
	public static inline var LAYER_CLONE_AFFIX			: String								= "vegaClone";
	
	public static function getDescMc( pAtlasId : String, pMcId : String) : MovieSymbol { return Resource.get( pAtlasId).library.movies[ pMcId]; }
	
	public static function getLayerWithPrefix( pPrefix : String, pAtlasId : String, pMcId : String) : Layer { return getLayerWithPrefixInSymbol( pPrefix, getDescMc( pAtlasId, pMcId)); }
	
	public static function getLayerWithPrefixInMovie( pPrefix : String, pCont : Movie) : Layer { return getLayerWithPrefixInSymbol( pPrefix, pCont.symbol); }
	
	public static function getLayersWithPrefixInMovie( pPrefix : String, pCont : Movie) : Array<Layer> { return getLayersWithPrefixInSymbol( pPrefix, pCont.symbol); }
	
	public static function getLayer( pName : String, pCont : Movie) : Container {
		if ( getLayerWithPrefixInSymbol( pName, pCont.symbol, true) != null) return pCont.getLayer( pName);
		else return null;
	}
	
	public static function getLayers( pCont : Movie) : Array<Layer> { return pCont.symbol.layers; }
	
	/**
	 * on crée un clone d'un layer pour pouvoir manipuler ses propriétés graphiques sans qu'il soit mis à jour à chaque frame automatiquement
	 * si un clone existe déjà, on le met à jour
	 * la source est rendue invisible
	 * /!\ méthode spécialisée pour la version patchée (nico) de pixi-flump-runtime
	 * @param	pMovie		instance de movie dont on cherche à cloner un layer
	 * @param	pLayer		nom complet de layer à cloner dans ce Movie
	 * @param	pCloneAffix	affix de clone pour pouvoir distinguer plusieurs instance de clones ; laisser null pour ne gérer qu'un seul clone
	 */
	public static function setCloneLayer( pMovie : Movie, pLayer : String, pCloneAffix : String = null) : Container {
		var lFrom		: Container			= pMovie.getLayer( pLayer);
		var lId			: String			= getSymbolId( lFrom);
		var lName		: String			= pLayer + LAYER_CLONE_AFFIX;
		var lContent	: DisplayObject		= lFrom.getChildAt( 0);
		var lClone		: Container;
		var lClCont		: DisplayObject;
		
		lFrom.visible = false;
		
		if ( pCloneAffix != null) lName += pCloneAffix;
		
		lClone = cast pMovie.getChildByName( lName);
		if( lClone == null){
			if ( AssetsMgr.instance != null && AssetsMgr.instance.getAssetDescById( lId) != null){
				lClone	= AssetsMgr.instance.getAssetInstance( lId);
				lClCont	= cast( lClone, AssetInstance).getContent();
			}else{
				lClone	= cast pMovie.addChildAt( new Container(), pMovie.getChildIndex( lFrom));
				
				if ( Std.is( lContent, Movie)){
					lClCont = new Movie( cast( lContent, Movie).symbolId, cast( lContent, Movie).resourceId);
				}else{
					lClCont = new Sprite( cast( lContent, Sprite).symbolId, cast( lContent, Sprite).resourceId);
				}
				
				lClone.addChild( lClCont);
			}
			
			lClone.name = lName;
		}else lClCont = lClone.getChildAt( 0);
		
		lClone.x		= lFrom.x;
		lClone.y		= lFrom.y;
		lClone.skew.x	= lFrom.skew.x;
		lClone.skew.y	= lFrom.skew.y;
		lClone.alpha	= lFrom.alpha;
		lClCont.scale.x	= lContent.scale.x;
		lClCont.scale.y	= lContent.scale.y;
		
		return lClone;
	}
	
	/**
	 * on vire un clone de layer créé avec ::setCloneLayer
	 * @param	pMovie		instance de movie dont on cherche à virer un clone de layer
	 * @param	pLayer		nom complet de layer dont on veut virer le clone
	 * @param	pCloneAffix	affix de clone pour pouvoir distinguer plusieurs instance de clones ; laisser null pour ne gérer qu'un seul clone
	 */
	public static function unsetCloneLayer( pMovie : Movie, pLayer : String, pCloneAffix : String = null) : Void {
		var lName	: String			= pLayer + LAYER_CLONE_AFFIX;
		var lClone	: Container;
		var lCont	: DisplayObject;
		
		pMovie.getLayer( pLayer).visible = true;
		
		if ( pCloneAffix != null) lName += pCloneAffix;
		
		lClone	= cast pMovie.getChildByName( lName);
		lCont	= lClone.getChildAt( 0);
		
		if ( Std.is( lClone, AssetInstance)){
			lClone.skew.x	= 0;
			lClone.skew.y	= 0;
			lClone.alpha	= 1;
			lCont.scale.x	= 1;
			lCont.scale.y	= 1;
			
			cast( pMovie.removeChild( lClone), AssetInstance).free();
		}else{
			lClone.removeChild( lCont).destroy();
			pMovie.removeChild( lClone).destroy();
		}
	}
	
	/**
	 * on vire tous les clones de layer créés avec ::setCloneLayer
	 * @param	pMovie	instance de movie dont on cherche à virer tous les clone de layer
	 */
	public static function unsetCloneLayers( pMovie : Movie) : Void {
		var lChild	: DisplayObject;
		
		for ( lChild in pMovie.children){
			if ( lChild.name.indexOf( LAYER_CLONE_AFFIX) != -1){
				if( lChild.name.indexOf( LAYER_CLONE_AFFIX) + LAYER_CLONE_AFFIX.length < lChild.name.length){
					unsetCloneLayer(
						pMovie,
						lChild.name.substr( 0, lChild.name.indexOf( LAYER_CLONE_AFFIX)),
						lChild.name.substr( lChild.name.indexOf( LAYER_CLONE_AFFIX) + LAYER_CLONE_AFFIX.length)
					);
				}else{
					unsetCloneLayer(
						pMovie,
						lChild.name.substr( 0, lChild.name.indexOf( LAYER_CLONE_AFFIX))
					);
				}
			}
		}
	}
	
	/**
	 * on récupère la texture d'un Sprite flump
	 * @param	pId		identifiant d'export du sprite
	 * @return	texture PIXI du sprite
	 */
	public static function getTextureFromSpId( pId : String) : Texture {
		var lRes : Resource	= Resource.getResourceForSprite( pId);
		
		return lRes.textures[ lRes.library.sprites[ pId].texture];
	}
	
	/**
	 * on récupère le nom d'un layer de Movie
	 * @param	pLayer	instance de layer
	 * @return	nom de layer du Movie parent, ou null si pas trouvé
	 */
	public static function getLayerName( pLayer : DisplayObject) : String {
		var lLayer	: Layer;
		
		if ( Std.is( pLayer.parent, Movie)) {
			for ( lLayer in cast( pLayer.parent, Movie).symbol.layers) {
				if ( cast( pLayer.parent, Movie).getLayer( lLayer.name) == pLayer) return lLayer.name;
			}
		}
		
		return null;
	}
	
	/**
	 * on récupère une instance de display object dans une couche de conteneur Flump
	 * @param	pMovie	instance de movie Flump conteneur
	 * @param	pLayer	nom de couche
	 * @return	instance de contenu de layer
	 */
	public static function getContent( pMovie : Movie, pLayer : String) : DisplayObject { return pMovie.getLayer( pLayer).getChildAt( 0); }
	
	/**
	 * on récupère le nom de symbole d'une instance de display object Flump
	 * @param	pDisp	instance Flump (movie ou sprite)
	 * @return	nom de symbole de cette instance, null si pas défini
	 */
	public static function getSymbolId( pDisp : DisplayObject) : String {
		if ( Std.is( pDisp, Movie)) return cast( pDisp, Movie).symbolId;
		else if ( Std.is( pDisp, Sprite)) return cast( pDisp, Sprite).symbolId;
		else return null;
	}
	
	public static function recursiveStop( pCont : Container) : Void {
		var lChild	: DisplayObject;
		
		if ( Std.is( pCont, Movie)) cast( pCont, Movie).stop();
		
		for ( lChild in pCont.children){
			if ( Std.is( lChild, Container)) recursiveStop( cast lChild);
		}
	}
	
	public static function recursivePlay( pCont : Container) : Void {
		var lChild	: DisplayObject;
		
		if ( Std.is( pCont, Movie)) cast( pCont, Movie).play();
		
		for ( lChild in pCont.children){
			if ( Std.is( lChild, Container)) recursivePlay( cast lChild);
		}
	}
	
	/**
	 * gotoAndStop récursif sur un conteneur graphique
	 * @param	pClip	conteneur graphique
	 * @param	pFrame	frame à laquelle se rendre dans tout le contenu
	 */
	public static function recursiveGotoAndStop( pCont : Container, pFrame : Int) : Void {
		var lChild	: DisplayObject;
		
		if ( Std.is( pCont, Movie)) cast( pCont, Movie).gotoAndStop( pFrame);
		
		for ( lChild in pCont.children){
			if ( Std.is( lChild, Container)) recursiveGotoAndStop( cast lChild, pFrame);
		}
	}
	
	public static function updateLayerInstanceRelativePos( pCont : Container, pX : Float, pY : Float) : Void {
		var lDisp	: DisplayObject	= pCont.getChildAt( 0);
		var lCoord	: Point			= pCont.toLocal( new Point( pX, pY), pCont.parent);
		
		lDisp.x	= lCoord.x;
		lDisp.y	= lCoord.y;
		
		/*var lDisp	: DisplayObject	= pCont.getChildAt( 0);
		
		lDisp.x	= ( pX - pCont.x) / pCont.scale.x;
		lDisp.y	= ( pY - pCont.y) / pCont.scale.y;*/
	}
	
	public static function setLayerXY( pCont : Container, pX : Float, pY : Float) : Void {
		var lDisp	: DisplayObject	= pCont.getChildAt( 0);
		
		lDisp.x	= ( pX - pCont.x) / pCont.scale.x;
		lDisp.y	= ( pY - pCont.y) / pCont.scale.y;
	}
	
	/**
	 * on positionne un layer à partir d'une abscisse virtuelle
	 * @param	pLayer	instance de layer de Movie
	 * @param	pX		abscisse virtuelle
	 */
	public static function setLayerX( pLayer : Container, pX : Float) : Void { pLayer.getChildAt( 0).x	= ( pX - pLayer.x) / pLayer.scale.x; }
	
	/**
	 * on positionne un layer à partir d'une ordonnée virtuelle
	 * @param	pLayer	instance de layer de Movie
	 * @param	pY		ordonnée virtuelle
	 */
	public static function setLayerY( pLayer : Container, pY : Float) : Void { pLayer.getChildAt( 0).y	= ( pY - pLayer.y) / pLayer.scale.y; }
	
	/**
	 * on récupère le x virtuel composite (conteneur + contenant) d'une instance de layer
	 * @param	pLayer	instance de layer de Movie
	 * @return	x virtuel composite (conteneur + contenant)
	 */
	public static function getLayerX( pLayer : Container) : Float { return pLayer.getChildAt( 0).x * pLayer.scale.x + pLayer.x; }
	
	/**
	 * on récupère le y virtuel composite (conteneur + contenant) d'une instance de layer
	 * @param	pLayer	instance de layer de Movie
	 * @return	y virtuel composite (conteneur + contenant)
	 */
	public static function getLayerY( pLayer : Container) : Float { return pLayer.getChildAt( 0).y * pLayer.scale.y + pLayer.y; }
	
	/**
	 * on récupère le xy virtuel composite (conteneur + contenant) d'une instance de layer
	 * @param	pLayer	instance de layer de Movie
	 * @return	xy virtuel composite (conteneur + contenant)
	 */
	public static function getLayerXY( pLayer : Container) : Point {
		var lChild	: DisplayObject	= pLayer.getChildAt( 0);
		
		return new Point( lChild.x * pLayer.scale.x + pLayer.x, lChild.y * pLayer.scale.y + pLayer.y);
	}
	
	/**
	 * on parcours un conteneur à la recherche de layers de Movie préfixée "mask", pour en faire des Graphics rectangulaire qui masquent le layer directement dessous
	 * @param	pCont	le conteneur à parser
	 */
	public static function recursiveApplyMask( pCont : Container) : Void {
		var lLayers	: Array<Layer>;
		var lLayer	: Layer;
		var lChild	: DisplayObject;
		var lModel	: Container;
		var lMasked	: DisplayObject;
		var lMask	: Graphics;
		var lRect	: Rectangle;
		
		if ( Std.is( pCont, Movie)){
			lLayers = getLayersWithPrefixInMovie( "mask", cast pCont);
			
			for ( lLayer in lLayers){
				lModel	= getLayer( lLayer.name, cast pCont);
				lMasked	= pCont.getChildAt( pCont.getChildIndex( lModel) - 1);
				lMask	= cast pCont.addChildAt( new Graphics(), pCont.getChildIndex( lModel));
				lRect	= UtilsPixi.getParentBounds( lModel);
				
				lMask.beginFill( 0, 1);
				lMask.drawRect( lRect.x, lRect.y, lRect.width, lRect.height);
				lMask.endFill();
				
				lMasked.mask	= lMask;
				lModel.visible	= false;
			}
		}
		
		for ( lChild in pCont.children){
			if ( Std.is( lChild, Container)) recursiveApplyMask( cast lChild);
		}
	}
	
	/**
	 * on libère récursivement un conteneur précédemment parsé et enrichi de mask Graphics
	 * @param	pCont	le conteneur à parser et libérer
	 */
	public static function recursiveRemoveMask( pCont : Container) : Void {
		var lChild	: DisplayObject;
		
		if ( Std.is( pCont, Movie)){
			for ( lChild in pCont.children){
				if ( lChild.mask != null){
					pCont.removeChild( lChild.mask).destroy();
					lChild.mask = null;
				}
			}
		}
		
		for ( lChild in pCont.children){
			if ( Std.is( lChild, Container)) recursiveRemoveMask( cast lChild);
		}
	}
	
	public static function createFullscreenBt( pCont : Movie) : MyButtonFlump {
		var lBt	: MyButtonFlump	= new MyButtonFlump( pCont, onBtFullscreen);
		
		if ( ApplicationMatchSize.instance.vars.f == "0") lBt.hide();
		
		return lBt;
	}
	
	static function onBtFullscreen( pE : EventTarget) : Void {
		if ( FullScreenApi.supportsFullScreen){
			if ( FullScreenApi.isFullScreen()){
				FullScreenApi.cancelFullScreen();
			}else {
				FullScreenApi.requestFullScreen( Browser.document.documentElement);
			}
		}
	}
	
	static function getLayerWithPrefixInSymbol( pPrefix : String, pDesc : MovieSymbol, pIsFull : Bool = false) : Layer {
		var lLayer	: Layer;
		
		for ( lLayer in pDesc.layers) {
			if ( pIsFull) {
				if ( lLayer.name == pPrefix) return lLayer;
			}else{
				if ( lLayer.name.indexOf( pPrefix) == 0) return lLayer;
			}
		}
		
		return null;
	}
	
	static function getLayersWithPrefixInSymbol( pPrefix : String, pDesc : MovieSymbol) : Array<Layer> {
		var lLayers	: Array<Layer>	= new Array<Layer>();
		var lLayer	: Layer;
		
		for ( lLayer in pDesc.layers){
			if ( lLayer.name.indexOf( pPrefix) == 0) lLayers.push( lLayer);
		}
		
		return lLayers;
	}
}