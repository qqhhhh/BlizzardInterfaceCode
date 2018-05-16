local function GetIconTextAndCurrenciesVisInfoData(widgetID)
	local widgetInfo = C_UIWidgetManager.GetIconTextAndCurrenciesWidgetVisualizationInfo(widgetID);
	if widgetInfo and widgetInfo.shownState ~= Enum.WidgetShownState.Hidden then
		return widgetInfo;
	end
end

UIWidgetManager:RegisterWidgetVisTypeTemplate(Enum.UIWidgetVisualizationType.IconTextAndCurrencies, {frameType = "FRAME", frameTemplate = "UIWidgetTemplateIconTextAndCurrencies"}, GetIconTextAndCurrenciesVisInfoData);

UIWidgetTemplateIconTextAndCurrenciesMixin = CreateFromMixins(UIWidgetBaseTemplateMixin);

local textureKitRegions = {
	["Icon"] = "%s",
}

function UIWidgetTemplateIconTextAndCurrenciesMixin:Setup(widgetInfo)
	UIWidgetBaseTemplateMixin.Setup(self, widgetInfo);
	self.currencyPool:ReleaseAll();

	SetupTextureKits(widgetInfo.textureKitID, self, textureKitRegions);
	self.Text:SetText(widgetInfo.text);
	local enabledState = widgetInfo.enabledState;
	if widgetInfo.enabledState == Enum.WidgetEnabledState.Enabled then
		enabledState = Enum.WidgetEnabledState.Highlight;
	end
	self.Text:SetEnabledState(enabledState);

	local disabled = (widgetInfo.enabledState == Enum.WidgetEnabledState.Disabled);
	self.Icon:SetDesaturated(disabled);

	local previousCurrencyFrame;
	local firstCurrencyFrame;

	for index, currencyInfo in ipairs(widgetInfo.currencies) do
		local currencyFrame = self.currencyPool:Acquire();
		currencyFrame:Show();

		currencyFrame:Setup(currencyInfo, disabled);

		if previousCurrencyFrame then
			currencyFrame:SetPoint("TOPLEFT", previousCurrencyFrame, "TOPRIGHT", 10, 0);
		else
			currencyFrame:SetPoint("BOTTOMLEFT", self.Icon, "BOTTOMRIGHT", 10, 0);
			firstCurrencyFrame = currencyFrame;
		end

		previousCurrencyFrame = currencyFrame;
	end

	local extraHeight = 0;

	local showDescription = (widgetInfo.descriptionShownState == Enum.WidgetShownState.Shown) and widgetInfo.description;
	if showDescription then
		self.Description:SetText(widgetInfo.description);
		self.Description:SetEnabledState(widgetInfo.descriptionEnabledState);
		self.Description:Show();

		self.Description:ClearAllPoints();
		if firstCurrencyFrame then
			self.Description:SetPoint("TOPLEFT", firstCurrencyFrame, "BOTTOMLEFT", 0, -2);
			extraHeight = self.Description:GetHeight();
		else
			self.Description:SetPoint("TOPLEFT", self.Text, "BOTTOMLEFT", 0, -2);
		end
	else
		self.Description:Hide();
	end

	self:SetHeight(32 + extraHeight);
end

function UIWidgetTemplateIconTextAndCurrenciesMixin:OnLoad()
	self.currencyPool = CreateFramePool("FRAME", self, "UIWidgetBaseCurrencyTemplate");
end

function UIWidgetTemplateIconTextAndCurrenciesMixin:OnReset()
	UIWidgetBaseTemplateMixin.OnReset(self);
	self.currencyPool:ReleaseAll();
end