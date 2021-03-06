package vega.utils;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;
import pixi.core.math.Point;
import pixi.core.math.shapes.Rectangle;
import pixi.interaction.EventTarget;
import vega.assets.AssetInstance;
import vega.shell.ApplicationMatchSize;

/**
 * ...
 * @author nico
 */
class UtilsPixi {
	/**
	 * calcul de bouding box du repère d'1 instance vers le repère de son parent ; ne prends en compte que le scale et la translation
	 * @param	pDisp	instance dont on cherche la bounding box
	 * @param	pRect	rectangle de bordures initiales dans repère de l'instance qui sera modifié et retourné après calcul, laisser null pour partir du ::getLocalBounds() de l'instance
	 * @return	bounding box dans parent de l'instance
	 */
	public static function getParentBounds( pDisp : DisplayObject, pRect : Rectangle = null) : Rectangle {
		var lRect	: Rectangle	= pRect == null ? pDisp.getLocalBounds() : pRect;
		
		lRect.x			= pDisp.x + ( pDisp.scale.x >= 0 ? lRect.x * pDisp.scale.x : ( lRect.x + lRect.width) * pDisp.scale.x);
		lRect.width		*= Math.abs( pDisp.scale.x);
		
		lRect.y			= pDisp.y + ( pDisp.scale.y >= 0 ? lRect.y * pDisp.scale.y : ( lRect.y + lRect.height) * pDisp.scale.y);
		lRect.height	*= Math.abs( pDisp.scale.y);
		
		return lRect;
	}
	
	/**
	 * calcul de bounding box dans repère du contenu de l'application ; ne gère que les translations et le scale
	 * /!\ l'instance doit forcément être enfant du contenu de l'application
	 * @param	pDisp	instance dont on cherche la bounding box
	 * @param	pRect	rectangle de bordures initiales dans repère de l'instance qui sera modifié et retourné après calcul, laisser null pour partir du ::getLocalBounds() de l'instance
	 * @return	bounding box dans repère du contenu de l'application ( ApplicationMatchSize::getContent)
	 */
	public static function getContentBounds( pDisp : DisplayObject, pRect : Rectangle = null) : Rectangle {
		var lTarget	: Container	= ApplicationMatchSize.instance.getContent();
		var lRect	: Rectangle	= pRect == null ? pDisp.getLocalBounds() : pRect;
		
		while ( pDisp != lTarget) {
			getParentBounds( pDisp, lRect);
			pDisp = pDisp.parent;
		}
		
		return lRect;
	}
	
	/**
	 * convertion de coordonées de repère du contenu de l'application en coordonées d'un petit fils de ce contenu ; ne gère que les translations et le scale et rotation
	 * /!\ : Flump n'utilise pas la propriété rotation, ça passe par les matrix => incompatible avec Flump
	 * /!\ : il existe déjà des méthodes de conversion : toLocal ou toGlobal ; MAIS : elles ne marchent pas sur du contenu dont la propriété rotation a été changé !
	 * @param	pChild	instance petit enfant du contenu
	 * @param	pCoord	coordonées dans repère du contenu à transformer ; l'instance même est modifiée
	 * @return	coordonées transformées dans repère du petit fils
	 */
	public static function contentToChild( pChild : DisplayObject, pCoord : Point) : Point {
		var lTrans	: Array<Array<Point>>	= new Array<Array<Point>>();
		var lTarget	: Container				= ApplicationMatchSize.instance.getContent();
		var lI		: Int;
		var lX		: Float;
		var lY		: Float;
		
		while ( pChild != lTarget) {
			lTrans.push( [ new Point( pChild.x, pChild.y), pChild.scale.clone()]);
			
			if ( pChild.rotation != 0){
				lTrans[ lTrans.length - 1].push( new Point( Math.cos( pChild.rotation), Math.sin( pChild.rotation)));
			}
			
			pChild = pChild.parent;
		}
		
		lI = lTrans.length - 1;
		while ( lI >= 0) {
			if ( lTrans[ lI].length > 2){
				lX	= pCoord.x;
				lY	= pCoord.y;
				
				pCoord.x	= ( lX * lTrans[ lI][ 2].x + lY * lTrans[ lI][ 2].y - lTrans[ lI][ 0].x * lTrans[ lI][ 2].x - lTrans[ lI][ 0].y * lTrans[ lI][ 2].y) / lTrans[ lI][ 1].x;
				pCoord.y	= ( lY * lTrans[ lI][ 2].x - lX * lTrans[ lI][ 2].y + lTrans[ lI][ 0].x * lTrans[ lI][ 2].y - lTrans[ lI][ 0].y * lTrans[ lI][ 2].x) / lTrans[ lI][ 1].y;
			}else{
				pCoord.x = ( pCoord.x - lTrans[ lI][ 0].x) / lTrans[ lI][ 1].x;
				pCoord.y = ( pCoord.y - lTrans[ lI][ 0].y) / lTrans[ lI][ 1].y;
			}
			
			lI--;
		}
		
		return pCoord;
	}
	
	public static function childToContent( pChild : DisplayObject, pCoord : Point) : Point {
		var lTarget	: Container	= ApplicationMatchSize.instance.getContent();
		var lCos	: Float;
		var lSin	: Float;
		var lX		: Float;
		var lY		: Float;
		
		while ( pChild != lTarget){
			if ( pChild.rotation != 0){
				lCos		= Math.cos( pChild.rotation);
				lSin		= Math.sin( pChild.rotation);
				lX			= pCoord.x * pChild.scale.x;
				lY			= pCoord.y * pChild.scale.y;
				
				pCoord.x	= lX * lCos - lY * lSin + pChild.x;
				pCoord.y	= lX * lSin + lY * lCos + pChild.y;
			}else{
				pCoord.x	= pCoord.x * pChild.scale.x + pChild.x;
				pCoord.y	= pCoord.y * pChild.scale.y + pChild.y;
			}
			
			pChild = pChild.parent;
		}
		
		return pCoord;
	}
	
	public static function childToChild( pFrom : DisplayObject, pTo : DisplayObject, pCoord : Point) : Point { return contentToChild( pTo, childToContent( pFrom, pCoord)); }
	
	/**
	 * addition de vecteurs ; pas d'instance créée, on utilise le point A
	 * @param	pPtA	vecteur A dans lequel est mis le résultat de l'addition
	 * @param	pPtB	vecteur B
	 * @return	vecteur A ajouté de B
	 */
	public static function addPt( pPtA : Point, pPtB : Point) : Point {
		pPtA.x	+= pPtB.x;
		pPtA.y	+= pPtB.y;
		
		return pPtA;
	}
	
	/**
	 * soustraction de vecteurs
	 * @param	pPtA	vecteur A
	 * @param	pPtB	vecteur B
	 * @return	nouveau vecteur différence
	 */
	public static function subPt( pPtA : Point, pPtB : Point) : Point { return new Point( pPtA.x - pPtB.x, pPtA.y - pPtB.y); }
	
	/**
	 * on teste si 2 rectangle se touchent
	 * @param	pRect1	instance 1 de rectangle
	 * @param	pRect2	instance 2 de rectangle
	 * @return	true si 1 et 2 se touchent, false sinon
	 */
	public static function intersects( pRect1 : Rectangle, pRect2 : Rectangle) : Bool {
		return pRect1.x <= pRect2.x + pRect2.width && pRect2.x <= pRect1.x + pRect1.width && pRect1.y <= pRect2.y + pRect2.height && pRect2.y <= pRect1.y + pRect1.height;
	}
	
	/**
	 * on vérifie si un point se trouve dans un rectangle (limites comprises)
	 * @param	pX		abscisse de point testé
	 * @param	pY		ordonnée de point testé
	 * @param	pRect	rectangle du test
	 * @param	pOffset	offset qui étend les limites du rectangle (si >0, si <0 diminue les limites) ; laisser 0 pour ne pas étendre les limites
	 * @return	true si point dans le rectangle, false sinon
	 */
	public static function isPtInRect( pX : Float, pY : Float, pRect : Rectangle, pOffset : Float = 0) : Bool {
		return pX >= pRect.x - pOffset && pX <= pRect.x + pRect.width + pOffset && pY >= pRect.y - pOffset && pY <= pRect.y + pRect.height + pOffset;
	}
	
	/**
	 * on vérifie si un point se trouve dans un rectangle expansé (coins arrondis)
	 * @param	pX		abscisse de point testé
	 * @param	pY		ordonnée de point testé
	 * @param	pRect	rectangle d etest
	 * @param	pExp	expansion du rectangle : si >0, les coins étendus sont arrondis
	 * @return	true si point dans le rectangle, false sinon
	 */
	public static function isPtInRectExp( pX : Float, pY : Float, pRect : Rectangle, pExp : Float) : Bool {
		if ( pExp <= 0) return isPtInRect( pX, pY, pRect, pExp);
		else{
			if ( pX < pRect.x && pY < pRect.y) return ( pX - pRect.x) * ( pX - pRect.x) + ( pY - pRect.y) * ( pY - pRect.y) <= pExp * pExp;
			else if ( pX < pRect.x && pY > pRect.y + pRect.height) return ( pX - pRect.x) * ( pX - pRect.x) + ( pY - pRect.y - pRect.height) * ( pY - pRect.y - pRect.height) <= pExp * pExp;
			else if ( pX > pRect.x + pRect.width && pY < pRect.y) return ( pX - pRect.x - pRect.width) * ( pX - pRect.x - pRect.width) + ( pY - pRect.y) * ( pY - pRect.y) <= pExp * pExp;
			else if( pX > pRect.x + pRect.width && pY > pRect.y + pRect.height) return ( pX - pRect.x - pRect.width) * ( pX - pRect.x - pRect.width) + ( pY - pRect.y - pRect.height) * ( pY - pRect.y - pRect.height) <= pExp * pExp;
			else return isPtInRect( pX, pY, pRect, pExp);
		}
	}
	
	public static function center( pDisp : Container) : Container {
		pDisp.x = -pDisp.width / 2;
		pDisp.y	= -pDisp.height / 2;
		
		return pDisp;
	}
	
	public static function setQuickBt( pDisp : DisplayObject, pListener : EventTarget -> Void) : Void {
		pDisp.buttonMode = true;
		pDisp.interactive = true;
		pDisp.addListener( "touchstart", pListener);
		pDisp.addListener( "mousedown", pListener);
	}
	
	public static function unsetQuickBt( pDisp : DisplayObject) : Void {
		pDisp.removeAllListeners( "touchstart");
		pDisp.removeAllListeners( "mousedown");
		pDisp.buttonMode = false;
		pDisp.interactive = false;
	}
}