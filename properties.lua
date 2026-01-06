-- LocalScript (compact code, lots of props)

local gui=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local root=gui.Bottom_UI.BottomFrame.Holder.List:WaitForChild("Thunderstorm") -- <- поправь путь если надо

local function split(s) local t={} for w in string.gmatch(s,"[^,%s]+") do t[#t+1]=w end return t end
local M={
  Frame=split("Name,Visible,Active,Selectable,Interactable,AnchorPoint,Position,Size,AbsolutePosition,AbsoluteSize,AutomaticSize,Rotation,LayoutOrder,ZIndex,ClipsDescendants,BackgroundColor3,BackgroundTransparency,BorderColor3,BorderSizePixel,GuiInset"),
  ImageLabel=split("Name,Visible,Active,Selectable,Interactable,AnchorPoint,Position,Size,AbsolutePosition,AbsoluteSize,AutomaticSize,Rotation,LayoutOrder,ZIndex,ClipsDescendants,BackgroundColor3,BackgroundTransparency,BorderColor3,BorderSizePixel,GuiInset,Image,ImageColor3,ImageTransparency,ScaleType,ResampleMode,TileSize,SliceCenter,SliceScale"),
  ImageButton=split("Name,Visible,Active,Selectable,Interactable,AnchorPoint,Position,Size,AbsolutePosition,AbsoluteSize,AutomaticSize,Rotation,LayoutOrder,ZIndex,ClipsDescendants,BackgroundColor3,BackgroundTransparency,BorderColor3,BorderSizePixel,GuiInset,Image,ImageColor3,ImageTransparency,ScaleType,ResampleMode,TileSize,SliceCenter,SliceScale,AutoButtonColor,Modal"),
  TextLabel=split("Name,Visible,Active,Selectable,Interactable,AnchorPoint,Position,Size,AbsolutePosition,AbsoluteSize,AutomaticSize,Rotation,LayoutOrder,ZIndex,ClipsDescendants,BackgroundColor3,BackgroundTransparency,BorderColor3,BorderSizePixel,GuiInset,Text,RichText,TextColor3,TextTransparency,TextStrokeColor3,TextStrokeTransparency,Font,TextSize,TextScaled,TextWrapped,TextXAlignment,TextYAlignment,LineHeight,TextTruncate"),
  UIStroke=split("Enabled,ApplyStrokeMode,Color,Transparency,Thickness,LineJoin"),
  UICorner=split("CornerRadius"),
  UIGradient=split("Enabled,Color,Transparency,Rotation,Offset"),
  UIScale=split("Scale"),
  UIAspectRatioConstraint=split("AspectRatio,AspectType,DominantAxis"),
  UIPadding=split("PaddingLeft,PaddingRight,PaddingTop,PaddingBottom"),
  UIListLayout=split("FillDirection,HorizontalAlignment,VerticalAlignment,SortOrder,Padding"),
  UIGridLayout=split("CellPadding,CellSize,FillDirection,HorizontalAlignment,VerticalAlignment,SortOrder,StartCorner"),
  UIPageLayout=split("Animated,AutoPlayCircular,CurrentPage,FillDirection,GamepadInputEnabled,Padding,ScrollWheelInputEnabled,TouchInputEnabled,TweenTime,EasingDirection,EasingStyle"),
}

local function dump(o)
  print(("\n[%s] %s"):format(o.ClassName,o:GetFullName()))
  local keys=M[o.ClassName] or (o:IsA("GuiObject") and M.Frame or {})
  for _,k in ipairs(keys) do local ok,v=pcall(function() return o[k] end); if ok then print(k.."="..tostring(v)) end end
  for k,v in pairs(o:GetAttributes()) do print("@"..k.."="..tostring(v)) end
end

dump(root); for _,c in ipairs(root:GetChildren()) do dump(c) end
