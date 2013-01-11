package com.weiplus.client;

import com.eclecticdesignstudio.motion.Actuate;
import nme.display.DisplayObject;
import nme.display.Sprite;
import nme.events.MouseEvent;
import nme.geom.Point;
import nme.geom.Rectangle;

/**
 * ...
 * @author Rocks Wang
 */

class ScrollPane extends Sprite {
	
	var container: Rectangle;
	var horizontal: Bool;
	var vertical: Bool;
	var point: Point;

	public function new(inContainer: Rectangle, inHorizontal: Bool, inVertical: Bool) {
		super();
		container = inContainer;
		horizontal = inHorizontal;
		vertical = inVertical;
		mouseEnabled = true;
		mouseChildren = true;
		addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		addEventListener(MouseEvent.MOUSE_UP, onUp);
		addEventListener(MouseEvent.MOUSE_MOVE, onMove);
		addEventListener(MouseEvent.MOUSE_OUT, onUp);
	}
	
	private function onDown(e: MouseEvent) {
		point = new Point(e.stageX, e.stageY);
	}
	
	private function onUp(e: MouseEvent) {
		if (point == null) return;
		var p = new Point(horizontal ? e.stageX : point.x, vertical ? e.stageY : point.y);
		
		var tx = x, ty = y;
		if (x > 0 || y > 0) {
			tx = ty = 0;
		} else {
			if (width > container.width && x + width < container.width) {
				tx = container.width - width;
			} else if (width <= container.width && x < 0) {
				tx = 0;
			}
			if (height > container.height && y + height < container.height) {
				ty = container.height - height;
			} else if (height < container.height && y < 0) {
				ty = 0;
			}
		}
		Actuate.tween(this, 0.2, { x: tx, y: ty } );
		
		point = null;
	}
	
	private function onMove(e: MouseEvent) {
		if (point == null) return;
		var p = new Point(horizontal ? e.stageX : point.x, vertical ? e.stageY : point.y);
		x += p.x - point.x;
		y += p.y - point.y;
		var xbound = container.width * 0.15, ybound = container.height * 0.15;
		//if (x > xbound) x = xbound;
		//if (x + width < container.width - xbound) x = container.width - xbound - width;
		//if (y > ybound) y = ybound;
		//if (y + height < container.height - ybound) y = container.height - ybound - height;
		point = p;
	}
	
}