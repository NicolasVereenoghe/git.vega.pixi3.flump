package vega.display;
import pixi.core.display.Container;
import pixi.core.display.DisplayObject;

/**
 * ...
 * @author nico
 */
class DepthMgr {
	var zone								: Container;
	var items								: Array<DepthCell>;
	
	public function new( pZone : Container) {
		zone	= pZone;
		items	= new Array<DepthCell>();
	}
	
	public function setDepth( pItem : DisplayObject, pDepth : Float) : Void {
		var lBeg	: Int	= 0;
		var lEnd	: Int	= items.length;
		var lMid	: Int	= Math.floor( ( lBeg + lEnd) / 2);
		
		while( lBeg < lEnd){
			if( pDepth > items[ lMid].depth){
				lBeg = lMid + 1;
			}else if( pDepth < items[ lMid].depth){
				lEnd = lMid;
			}else break;
			
			lMid = Math.floor( ( lBeg + lEnd) / 2);
		}
		
		items.insert( lMid, new DepthCell( pItem, pDepth));
		
		if( items.length == lMid + 1) zone.setChildIndex( pItem, zone.children.length - 1);
		else zone.setChildIndex( pItem, zone.getChildIndex( items[ lMid + 1].mc));
	}
	
	/**
	 * update the depth of an already registered item
	 * @param	pItem	the displayed item which depth should be updated
	 * @param	pDeth	its new depth hint comparative value
	 */
	public function updateDepth( pItem : DisplayObject, pDepth : Float) : Void {
		freeDepth( pItem);
		zone.setChildIndex( pItem, zone.children.length - 1);
		setDepth( pItem, pDepth);
	}
	
	public function freeDepth( pItem : DisplayObject) : Void {
		var lBeg	: Int	= 0;
		var lEnd	: Int	= items.length;
		var lMid	: Int	= Math.floor( ( lBeg + lEnd) / 2);
		var lDepth	: Int	= zone.getChildIndex( pItem);
		
		while( lBeg < lEnd){
			if( lDepth > zone.getChildIndex( items[ lMid].mc)){
				lBeg = lMid + 1;
			}else if( lDepth < zone.getChildIndex( items[ lMid].mc)){
				lEnd = lMid;
			}else break;
			
			lMid = Math.floor( ( lBeg + lEnd) / 2);
		}
		
		items.splice( lMid, 1);
	}
}

class DepthCell {
	public var mc		: DisplayObject;
	public var depth	: Float;
	
	public function new( pMc : DisplayObject, pD : Float){
		mc		= pMc;
		depth	= pD;
	}
}