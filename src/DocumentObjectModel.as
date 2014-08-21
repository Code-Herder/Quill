package WorldCities.Widgets
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.ImageLoader;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.core.FeathersControl;
	import feathers.layout.AnchorLayout;
	import feathers.layout.AnchorLayoutData;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.HorizontalLayoutData;
	import feathers.layout.ILayoutData;
	import feathers.layout.VerticalLayout;
	import feathers.layout.VerticalLayoutData;
	
	import r1.deval.D;
	
	import sk.yoz.net.URLRequestBufferBulkLoader;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.textures.Texture;
	
	import utils.LabelStyleFactory;
	import feathers.controls.List;
	import feathers.controls.PageIndicator;
	
	public class DocumentObjectModel extends  starling.events.EventDispatcher
	{
		private var mRoot:FeathersControl;
		private var mJSonReady:Boolean = false;
		private var mDocumentUrl:String = null;
		
		private var mDebugOverEnabled:Boolean = false;
		private var mDebugButton:Button = null;
		
		private var mElementsDict:Dictionary = new Dictionary();
		
		public static const DOCUMENT_LOAD_COMPLETE:String = "DocumentObjectModel_LoadingComplete";
		
		public function DocumentObjectModel( url:String, container:FeathersControl, debugOverlayEnabled:Boolean )
		{
			mDebugOverEnabled = debugOverlayEnabled;
		
			mRoot = container;
			mDocumentUrl = url
			loadDocument();
		}
		
		public function loadDocument() : void
		{
			var documentUrl:URLRequest = new URLRequest(mDocumentUrl);
			
			var documentLoader:URLLoader = new URLLoader();
			documentLoader.dataFormat = URLLoaderDataFormat.TEXT;
			documentLoader.addEventListener( flash.events.Event.COMPLETE, documentLoaded,false,0,true );
			documentLoader.addEventListener(flash.events.IOErrorEvent.IO_ERROR, errorLoadingDocument,false,0,true );
			documentLoader.load(documentUrl);			
		}
		
		public function getElement( selector:String ) : Object
		{
			return mElementsDict[selector];
		}
		
		private function documentLoaded(event:flash.events.Event) : void
		{
			var documentLoader:URLLoader = URLLoader(event.target);
			( event.target as URLLoader).removeEventListener( flash.events.Event.COMPLETE, documentLoaded );
			( event.target as URLLoader).removeEventListener( flash.events.IOErrorEvent.IO_ERROR, documentLoaded );


			var jsonDOM:Object = null;
			try
			{
				jsonDOM = JSON.parse(event.target.data);
			}
			catch( e:Error ) {
				var errorMsg:String = e.name + ":" + e.message;
				var aLayout:AnchorLayout = new AnchorLayout();
				var lGroup:LayoutGroup = new LayoutGroup();
				lGroup.width = mRoot.width;
				lGroup.height = mRoot.height;
				lGroup.layout = aLayout;
				mRoot.addChild( lGroup );
				
				var quad:Quad = new Quad(1, 1, 0xFF0000);
				var quadAdapter:FeathersControlAdapter = new FeathersControlAdapter();
				quadAdapter.displayObject = quad;
				
				var alData:AnchorLayoutData = new AnchorLayoutData();
				alData.left = 10;
				alData.right = 10;
				alData.top = 10;
				alData.bottom = 10;				
				quadAdapter.layoutData = alData;
				
				lGroup.addChild( quadAdapter );
				
				var warning:Label = new Label();
				warning.text = "UI Loading error:\n" + errorMsg;
				
				alData = new AnchorLayoutData();
				alData.left = 20;
				alData.right = 20;
				alData.verticalCenter = 0;
				warning.layoutData = alData;
				
				lGroup.addChild( warning );
				LabelStyleFactory.formatTextLabel( warning, "center", mRoot.stage.height * 0.04, 0xFFFFFF );
			}

			if ( jsonDOM )
			{
				for each ( var widget:Object in jsonDOM.root)
				{
					var sprite:DisplayObject = loadWidget( widget, mRoot ) as DisplayObject;
					if ( sprite != null )
					{
						mRoot.addChild( sprite );
					}
				}
	
				for each ( widget in jsonDOM.root)
					postAddChildLoad( widget );
			}
			
			if ( mDebugOverEnabled == true )
			{
				mDebugButton = new Button();
				mDebugButton.label = "reload";
				mDebugButton.x = mRoot.width * 0.20;
				mDebugButton.addEventListener(starling.events.Event.TRIGGERED, RealodButtonListener );
				mRoot.addChild( mDebugButton );
			}
			
			if ( jsonDOM )
				dispatchEventWith(DOCUMENT_LOAD_COMPLETE, false, null);
		}		
		
		private function RealodButtonListener( event:starling.events.Event ): void
		{
			while ( mRoot.numChildren > 0 )
				mRoot.removeChildAt( 0 );
			
			loadDocument();
		}		
		
		private function evalSizeFunction( sizeCode:String, widgetParent:DisplayObject ) : Number
		{
			var size:Number = D.evalToNumber(sizeCode, { parent_width:widgetParent.width, parent_height:widgetParent.height, stage_width:mRoot.stage.width, stage_height:mRoot.stage.height });
			return size;
		}
		
		private function loadWidgetProperties( widgetInst:Object, widgetParent:DisplayObject, widgetDesc:Object ) : void
		{
			for ( var item:String in widgetDesc )
			{
				if ( widgetInst.hasOwnProperty(item) )
				{
					if (widgetDesc[item] is String )
					{
						if ( widgetDesc[item] == "meta_null" )
							widgetDesc[item] = null;
						
						if ( item == "nameList" )
						{
							widgetInst[item].add(widgetDesc[item] );
						}
						else if ( item == "width" || item == "height" || item == "x" || item == "y" || item == "actualWidth" || item == "actualHeight" ||
								  item == "right" || item == "left" || item == "bottom" || item == "top" )
						{
							widgetInst[item] = evalSizeFunction( widgetDesc[item], widgetParent );
						}						
						else						
							widgetInst[item] = widgetDesc[item];
					}
					else
					{
						widgetInst[item] = loadWidget( widgetDesc[item], widgetInst as DisplayObject);
					}
				}
			}			
		}
		
		private function loadWidget( widget:Object, parent:DisplayObject ) : Object
		{
			var output:Object = null;
			
			if ( widget.meta_type == "LayoutGroup" )
			{
				var group:LayoutGroup = new LayoutGroup();
				
				loadWidgetProperties( group, parent, widget );

				if ( widget.hasOwnProperty( "meta_childs" ) )
				{
					for each ( var subWidget:Object in widget.meta_childs )
					{
						var subSprite:DisplayObject = loadWidget( subWidget, group ) as DisplayObject;
						if ( subSprite != null )
						{
							group.addChild( subSprite );
						}
					}
				}

				output = group;				
			}
			else if ( widget.meta_type == "HorizontalLayout" )
			{
				var hlayout:HorizontalLayout = new HorizontalLayout();
				loadWidgetProperties( hlayout, parent, widget );
				output = hlayout;
			}
			else if ( widget.meta_type == "HorizontalLayoutData" )
			{
				var hlayoutData:HorizontalLayoutData = new HorizontalLayoutData();
				loadWidgetProperties( hlayoutData, parent, widget );
				output = hlayoutData;
			}
			else if ( widget.meta_type == "VerticalLayout" )
			{
				var vlayout:VerticalLayout = new VerticalLayout();
				loadWidgetProperties( vlayout, parent, widget );
				output = vlayout;
			}
			else if ( widget.meta_type == "VerticalLayoutData" )
			{
				var vlayoutData:VerticalLayoutData = new VerticalLayoutData();
				loadWidgetProperties( vlayoutData, parent, widget );
				output = vlayoutData;
			}
			else if ( widget.meta_type == "AnchorLayout" )
			{
				var anchorLayout:AnchorLayout = new AnchorLayout();
				loadWidgetProperties( anchorLayout, parent, widget );
				output = anchorLayout;
			}			
			else if ( widget.meta_type == "AnchorLayoutData" )
			{
				var anchorLayoutData:AnchorLayoutData = new AnchorLayoutData();
				loadWidgetProperties( anchorLayoutData, parent, widget );
				
				if ( widget.hasOwnProperty( "meta_rightAnchorDisplayObject" ) )
				{
					if ( mElementsDict[widget.meta_rightAnchorDisplayObject] !== undefined )
					{
						anchorLayoutData.rightAnchorDisplayObject = mElementsDict[widget.meta_rightAnchorDisplayObject];
					}
				}
				if ( widget.hasOwnProperty( "meta_leftAnchorDisplayObject" ) )
				{
					if ( mElementsDict[widget.meta_leftAnchorDisplayObject] !== undefined )
					{
						anchorLayoutData.leftAnchorDisplayObject = mElementsDict[widget.meta_leftAnchorDisplayObject];
					}
				}
				if ( widget.hasOwnProperty( "meta_topAnchorDisplayObject" ) )
				{
					if ( mElementsDict[widget.meta_topAnchorDisplayObject] !== undefined )
					{
						anchorLayoutData.topAnchorDisplayObject = mElementsDict[widget.meta_topAnchorDisplayObject];
					}
				}
				if ( widget.hasOwnProperty( "meta_bottomAnchorDisplayObject" ) )
				{
					if ( mElementsDict[widget.meta_bottomAnchorDisplayObject] !== undefined )
					{
						anchorLayoutData.bottomAnchorDisplayObject = mElementsDict[widget.meta_bottomAnchorDisplayObject];
					}
				}
				output = anchorLayoutData;
			}			
			else if ( widget.meta_type == "Button" )
			{
				var button:Button = new Button();
				loadWidgetProperties( button, parent, widget );
				output = button;
			}
			else if ( widget.meta_type == "Label" )
			{
				var label:Label = new Label();
				loadWidgetProperties( label, parent, widget );
				output = label;				
			}			
			else if ( widget.meta_type == "PageIndicator" )
			{
				var pageIndicator:PageIndicator = new PageIndicator();
				loadWidgetProperties( pageIndicator, parent, widget );
				output = pageIndicator;				
			}			
			else if ( widget.meta_type == "GroupedList" )
			{
				var glist:GroupedList = new GroupedList()
				loadWidgetProperties( glist, parent, widget );
				output = glist;
			}
			else if ( widget.meta_type == "List" )
			{
				var list:List = new List()
				loadWidgetProperties( list, parent, widget );
				output = list;
			}
			else if ( widget.meta_type == "ImageLoader" )
			{
				var imageLoader:ImageLoader = new ImageLoader ()
				loadWidgetProperties( imageLoader, parent, widget );
				output = imageLoader;
			}
			else if ( widget.meta_type == "Quad" )
			{
				var quad:Quad = new Quad(1, 1, 0xFFFFFFFF);
				loadWidgetProperties( quad, parent, widget );

				var quadAdapter:FeathersControlAdapter = new FeathersControlAdapter();
				quadAdapter.displayObject = quad;

				if ( widget.hasOwnProperty( "layoutData" ) )
				{
					quadAdapter.layoutData = loadWidget( widget.layoutData, parent) as ILayoutData;
				}
				
				output = quadAdapter;
			}			
			
			if ( widget.hasOwnProperty( "meta_id" ) )
			{
				mElementsDict[widget.meta_id] = output;
			}
			
			if ( output == null )
				trace ( "\nWARNING: A widget was invalid: " + widget.meta_type );

			widget.Instance = output;
			
			return output;
		}

		
		private function postAddChildLoad( widgetDescription:Object ) : void
		{
			if ( widgetDescription.meta_type == "LayoutGroup" )
			{
				if ( widgetDescription.hasOwnProperty( "meta_childs" ) )
				{
					for each ( var subWidgetDescription:Object in widgetDescription.meta_childs )
						postAddChildLoad( subWidgetDescription );
				}
			}			
			else if ( widgetDescription.meta_type == "Button" )
			{
				var button:Button = widgetDescription.Instance as Button;
				if ( widgetDescription.hasOwnProperty( "meta_format_button" ) )
				{					
					LabelStyleFactory.formatTextButton( button, widgetDescription.meta_format_button.align, evalSizeFunction(widgetDescription.meta_format_button.font_size, button), widgetDescription.meta_format_button.color );
				}				
			}		
			else if ( widgetDescription.meta_type == "Label" )
			{
				var label:Label = widgetDescription.Instance as Label;
				if ( widgetDescription.hasOwnProperty( "meta_format_label" ) )
				{					
					LabelStyleFactory.formatTextLabel( label, widgetDescription.meta_format_label.align, evalSizeFunction(widgetDescription.meta_format_label.font_size, label), widgetDescription.meta_format_label.color );
				}				
			}		
		}
		
		private function errorLoadingDocument(errorEvent:flash.events.IOErrorEvent):void
		{
			( errorEvent.target as URLLoader).removeEventListener( flash.events.Event.COMPLETE, documentLoaded );
			( errorEvent.target as URLLoader).removeEventListener( flash.events.IOErrorEvent.IO_ERROR, documentLoaded );			
		}		
	}
}