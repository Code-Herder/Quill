package WorldCities.Widgets
{
	import com.greensock.easing.Quad;
	
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	import feathers.core.FeathersControl;
	import feathers.core.IFeathersControl;
	import feathers.core.IFocusDisplayObject;
	import feathers.core.ITextRenderer;
	import feathers.core.IToggle;
	import feathers.core.IValidating;
	import feathers.core.PropertyProxy;
	import feathers.events.FeathersEventType;
	import feathers.skins.StateWithToggleValueSelector;
	
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	/**
	 * Dispatched when the button is selected or unselected. A button's
	 * selection may be changed by the user when <code>isToggle</code> is set to
	 * <code>true</code>. The selection may be changed programmatically at any
	 * time, regardless of the value of <code>isToggle</code>.
	 *
	 * @eventType starling.events.Event.CHANGE
	 */
	[Event(name="change",type="starling.events.Event")]
	
	public class FeathersControlAdapter extends FeathersControl
	{
		private var displayObj:starling.display.DisplayObject = null;
		
		public function FeathersControlAdapter()
		{
		}		
		
		override protected function draw():void
		{
			if ( displayObject != null )
			{
				displayObject.width = this.actualWidth;
				displayObject.height = this.actualHeight;
			}
		}

		public function get displayObject():DisplayObject
		{
			return this.displayObj;
		}
		
		public function set displayObject(value:DisplayObject):void
		{
			if ( displayObj != null )
				this.removeChild( displayObj );
			
			displayObj = value;
			
			if ( displayObj != null )
				this.addChild( displayObj );
		}
		
	}
}