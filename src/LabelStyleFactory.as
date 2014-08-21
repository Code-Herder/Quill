package utils
{
	import flash.text.engine.ElementFormat;
	
	import feathers.controls.Label;
	import feathers.controls.text.TextBlockTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.controls.Button;

	public class LabelStyleFactory
	{
		public function LabelStyleFactory()
		{
		}
		
		static public function formatTextLabel( label:Label, alignement:String, size:int, color:int ):void
		{
			label.textRendererFactory = function():ITextRenderer
			{
				var textRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
				
				if ( alignement == "center")
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_CENTER;
				else if ( alignement == "left")
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_LEFT;
				else if ( alignement == "right")
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_RIGHT;
				else
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_LEFT;
				
				return textRenderer;
			}	
			var ef2:ElementFormat = label.textRendererProperties.elementFormat.clone();
			if ( size != -1 )
				ef2.fontSize = size;
			ef2.color = color;
			label.textRendererProperties.elementFormat = ef2;			
		}

		static public function formatTextButton( button:Button, alignement:String, size:int, color:int ):void
		{			
			button.labelFactory = function():ITextRenderer
			{
				var textRenderer:TextBlockTextRenderer = new TextBlockTextRenderer();
				
				if ( alignement == "center")
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_CENTER;
				else if ( alignement == "left")
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_LEFT;
				else if ( alignement == "right")
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_RIGHT;
				else
					textRenderer.textAlign = TextBlockTextRenderer.TEXT_ALIGN_LEFT;
				
				return textRenderer;
			}	
			var ef2:ElementFormat = button.defaultLabelProperties.elementFormat.clone();
			if ( size != -1 )
				ef2.fontSize = size;
			ef2.color = color;
			button.defaultLabelProperties.elementFormat = ef2;			
		}
	}
}