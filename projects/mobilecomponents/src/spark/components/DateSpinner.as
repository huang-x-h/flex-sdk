////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2011 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////
package spark.components
{
import flash.events.Event;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.collections.ISort;
import mx.core.IFactory;
import mx.core.IVisualElementContainer;
import mx.core.mx_internal;
import mx.events.FlexEvent;

import spark.collections.Sort;
import spark.collections.SortField;
import spark.components.calendarClasses.DateAndTimeProvider;
import spark.components.calendarClasses.DateSelectorDisplayMode;
import spark.components.calendarClasses.YearProvider;
import spark.components.supportClasses.SkinnableComponent;
import spark.events.IndexChangeEvent;
import spark.formatters.DateTimeFormatter;
import spark.formatters.NumberFormatter;
import spark.globalization.supportClasses.CalendarDate;
import spark.globalization.supportClasses.DateTimeFormatterEx;

use namespace mx_internal;

//--------------------------------------
//  Events
//--------------------------------------
/**
 *  Dispatched after the selected date has been changed by the user.
 *
 *  @eventType flash.events.Event.CHANGE
 *  
 *  @langversion 3.0
 *  @playerversion AIR 3
 *  @productversion Flex 4.5.2
 */
[Event(name="change", type="flash.events.Event")]

/**
 *  Dispatched after the selected date has been changed, either
 *  by the user (i.e. interactively) or programmatically.
 *
 *  @eventType mx.events.FlexEvent.VALUE_COMMIT
 *  
 *  @langversion 3.0
 *  @playerversion AIR 3
 *  @productversion Flex 4.5.2
 */
[Event(name="valueCommit", type="mx.events.FlexEvent")]

//--------------------------------------
//  Styles
//--------------------------------------

include "../styles/metadata/StyleableTextFieldTextStyles.as"

/**
 *  The locale of the component. Controls how dates are formatted, e.g. in what order the fields
 *  are listed and what additional date-related characters are shown, if any. Uses standard locale
 *  identifiers as described in Unicode Technical Standard #35. For example "en", "en_US" and "en-US"
 *  are all English, "ja" is Japanese. If the specified locale is not supported on the platform, "en_US"
 *  will be used. To determine if a locale is supported, use 
 *  <code>DateTimeFormatter.getAvailableLocaleIDNames()</code>
 *
 *  <p>The default value is undefined. This property inherits its value from an ancestor; if still
 *  undefined, it inherits from the global <code>locale</code> style.</p>
 *
 *  <p>When using the Spark formatters and globalization classes, you can set this style on the root
 *  application to the value of the <code>LocaleID.DEFAULT</code> constant.
 *  Those classes will then use the client operating system's international preferences.</p>
 *
 *  @langversion 3.0
 *  @playerversion AIR 3
 *  @productversion Flex 4.5.2
 */
[Style(name="locale", type="String", inherit="yes")]

/**
 *  Color applied for the date items that match today's date.
 *  For example, if this is set to "0x0000FF" and today's date is 1/1/2011, then the month
 *  "January", the date "1", and the year "2011" will be in blue text on the spinners. This color
 *  is not applied to time items.
 * 
 *  @default #0058A8
 * 
 *  @langversion 3.0
 *  @playerversion AIR 3
 *  @productversion Flex 4.5.2
 */
[Style(name="accentColor", type="uint", format="Color", inherit="yes")]

//--------------------------------------
//  Other metadata
//--------------------------------------

[IconFile("DateSpinner.png")]

/**
 *  The DateSpinner control presents an interface for picking a particular date or time. 
 * 
 * <p>The DateSpinner control can display the date, the time, or the date and time, based on the 
 *  value of the <code>displayMode</code> property.</p>
 * 
 *  <p>The UI for the control is made up of a series of SpinnerList controls wrapped inside
 *  a SpinnerListContainer that show the
 *  currently-selected date. Through touch or mouse interaction, users
 *  can adjust the selected date.</p>
 * 
 *  <p>The DateSpinnerSkin only defines some sizing properties. 
 *  To change the appearance of the DateSpinner control, you typically reskin the underlying 
 *  SpinnerListSkin or SpinnerListContainerSkin.</p>
 * 
 *  @mxml <p>The <code>&lt;s:DateSpinner&gt;</code> tag inherits all of the tag
 *  attributes of its superclass and adds the following tag attributes:</p>
 *
 *  <pre>
 *  &lt;s:DateSpinner
 *    <strong>Properties</strong>
 *    displayMode="date|time|dateAndTime"
 *    maxDate="null"
 *    minDate="null"
 *    minuteStepSize="1"
 *    selectedDate=""
 * 
 *    <strong>Styles</strong>
 *    accentColor="0x0058A8"
 *  /&gt;
 *  </pre>
 * 
 *  @see spark.components.SpinnerList
 * 
 *  @langversion 3.0
 *  @playerversion AIR 3
 *  @productversion Flex 4.5.2
 */

public class DateSpinner extends SkinnableComponent
{
    //--------------------------------------------------------------------------
    //
    //  Class constants
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Constant for specifying to createDateItemList() that the list is for showing
     *  years.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    protected static const YEAR_ITEM:String = "yearItem";

    /**
     *  Constant for specifying to createDateItemList() that the list is for showing
     *  months.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    protected static const MONTH_ITEM:String = "monthItem";

    /**
     *  Constant for specifying to createDateItemList() that the list is for showing
     *  dates of the month or year.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    protected static const DATE_ITEM:String = "dateItem";
    
    /**
     *  Constant for specifying to createDateItemList() that the list is for showing
     *  hours.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    protected static const HOUR_ITEM:String = "hourItem";
    
    /**
     *  Constant for specifying to createDateItemList() that the list is for showing
     *  minutes.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    protected static const MINUTE_ITEM:String = "minuteItem";
    
    /**
     *  Constant for specifying to createDateItemList() that the list is for showing
     *  meridian options.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    protected static const MERIDIAN_ITEM:String = "meridianItem";
    
    private static const MS_IN_DAY:Number = 1000 * 60 * 60 * 24;
    
    // choosing January 1980 to guarantee 31 days in the month
    private static const JAN1980_IN_MS:Number = 315561660000;
    
    // meridian
    private static const AM:String = "am";
    private static const PM:String = "pm";

    // default min/max date
    private static const MIN_DATE_DEFAULT:Date = new Date(1601, 0, 1);
    private static const MAX_DATE_DEFAULT:Date = new Date(9999, 11, 31, 23, 59, 59, 999);
    
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    /**
     *  Constructor.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    public function DateSpinner()
    {
        super();
        
        // TODO: the DateTimeFormatter should use the same styles as this DateSpinner
        // dateTimeFormatter.styleParent = this;
    }
    
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    private var dispatchValueCommitEvent:Boolean = false;
    private var dispatchChangeEvent:Boolean = false;
    
    private var populateYearDataProvider:Boolean = true;
    private var populateMonthDataProvider:Boolean = true;
    private var populateDateDataProvider:Boolean = true;
    private var populateHourDataProvider:Boolean = true;
    private var populateMinuteDataProvider:Boolean = true;
    private var populateMeridianDataProvider:Boolean = true;
    
    private var refreshDateTimeFormatter:Boolean = true;
    
    // the internal DateTimeFormatter that provides a set of extended functionalities
    private var dateTimeFormatterEx:DateTimeFormatterEx = new DateTimeFormatterEx();
    
    private var dateTimeFormatter:DateTimeFormatter = new DateTimeFormatter();
    
    // the DateTimeFormatterEx that uses MMMEEEd skeleton pattern to identify
    // the longest dateList item in DATE_AND_TIME mode
    private var dayMonthDateFormatter:DateTimeFormatterEx;
    
    // the NumberFormatter to identify the longest yearList item in DATE mode
    private var numberFormatter:NumberFormatter;
    
    // caching the longest digit (the array value) between index and 9, inclusive, and refresh when locale changes
    private var longestDigitArray:Array = new Array(-1, -1, -1, -1, -1, -1, -1, -1, -1, -1);
    
    private var dateObj:Date = new Date();
    private var use24HourTime:Boolean;
    
    // store the longest dateList item and updates only when locale changes
    private var longestDateItem:Object;
    private var longestYearItem:Object;
    
    // controls whether we should snap to or animate to spinner values
    private var useAnimationToSetSelectedDate:Boolean = false;
    
    // keep track of which lists are currently animating for programmatic animations
    private var listsBeingAnimated:Dictionary = new Dictionary();

    //--------------------------------------------------------------------------
    //
    //  Skin parts 
    //
    //--------------------------------------------------------------------------
    
    [SkinPart]
    /**
     *  The default factory for creating SpinnerList interfaces for all fields.
     *  This is used by the createDateItemList() method.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    public var dateItemList:IFactory;
    
    [SkinPart] 
    /**
     *  The container for the date part lists
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    public var listContainer:IVisualElementContainer;
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    /**
     *  The SpinnerList showing the year field of the date.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2 
     */ 
    protected var yearList:SpinnerList;

    /**
     *  The SpinnerList showing the month field of the date.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2 
     */ 
    protected var monthList:SpinnerList;
    
    /**
     *  The SpinnerList showing the date field of the date.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2 
     */ 
    protected var dateList:SpinnerList;
    
    /**
     *  The SpinnerList showing the hour field of the date.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2 
     */ 
    protected var hourList:SpinnerList;
    
    /**
     *  The SpinnerList showing the minutes field of the date.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2 
     */ 
    protected var minuteList:SpinnerList;
    
    /**
     *  The SpinnerList showing the meridian field (AM/PM) of the date.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2 
     */ 
    protected var meridianList:SpinnerList;
    
    //----------------------------------
    //  displayMode
    //----------------------------------
    
    private var _displayMode:String = DateSelectorDisplayMode.DATE;
    
    private var displayModeChanged:Boolean = false;
    
    [Inspectable(category="General", enumeration="date,time,dateAndTime", defaultValue="date")]
    
    /**
     *  Mode the DateSpinner is currently using for display. You can set this value to the constants defined in the 
     *  DateSelectorDisplayMode class, or to their string equivalents.
     * 
     *  <p>The following table describes the possible values:
     *     <table class="innertable">
     *     <tr><th>Mode (String equivalent)</th><th>Description</th></tr>
     *     <tr><td><code>DateSelectorDisplayMode.DATE</code> ("date")</td><td>Displays the month, day, and year. This is the default mode.</td></tr>
     *     <tr><td><code>DateSelectorDisplayMode.TIME</code> ("time")</td><td>Displays the day of week, month, day, and time.</td></tr>
     *     <tr><td><code>DateSelectorDisplayMode.DATE_AND_TIME</code> ("dateAndTime")</td><td>Displays the hours and minutes, and, if the locale supports it, the AM/PM selector.</td></tr>
     *     </table>
     *   </p>
     * 
     *  @see spark.components.calendarClasses.DateSelectorDisplayMode
     * 
     *  @default DateSelectorDisplayMode.DATE
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */     
    public function get displayMode():String
    {
        return _displayMode;
    }
    
    /**
     *  @private
     */     
    public function set displayMode(value:String):void
    {
        if (_displayMode == value || value == null)
            return;
        
        _displayMode = value;
        displayModeChanged = true;
        
        if (value == DateSelectorDisplayMode.TIME)
        {
            populateHourDataProvider = true;
            populateMinuteDataProvider = true;
            populateMeridianDataProvider = true;
        }
        else if (value == DateSelectorDisplayMode.DATE_AND_TIME)
        {
            populateYearDataProvider = true;
            populateMonthDataProvider = true;
            populateDateDataProvider = true;
            populateHourDataProvider = true;
            populateMinuteDataProvider = true;
            populateMeridianDataProvider = true;
        }
        else // default mode is DATE
        {
            populateYearDataProvider = true;
            populateMonthDataProvider = true;
            populateDateDataProvider = true;
        }
        
        syncSelectedDate = true; // force lists to spin to current selected date
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  maxDate
    //----------------------------------
    
    private var _maxDate:Date;
    
    private var maxDateChanged:Boolean = false;
    
    /**
     *  Maximum selectable date; only this date and dates before this date are selectable.
     * 
     *  @default If maxDate is null, the value defaults to 100 years after
     *           the currently selected date in DATE mode, and 100 days 
     *           after the currently selected date in DATE_AND_TIME mode.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    public function get maxDate():Date
    {
        return _maxDate != null ? _maxDate : MAX_DATE_DEFAULT;
    }
    
    /**
     *  @private
     */     
    public function set maxDate(value:Date):void
    {
        if ((_maxDate && value && _maxDate.time == value.time)
            || (_maxDate == null && value == null))
            return;

        _maxDate = value;
        populateYearDataProvider = true;
        populateDateDataProvider = true;
        maxDateChanged = true;
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  minDate
    //----------------------------------
    
    private var _minDate:Date;
    
    private var minDateChanged:Boolean = false;
    
    // TODO: add reference after the global team adds the doc
    /**
     *  Minimum selectable date; only this date and dates after this date are selectable.
     * 
     *  @default If minDate is null, the value defaults to 100 years prior to
     *           the currently selected date in DATE mode, and 100 days prior
     *           to the currently selected date in DATE_AND_TIME mode.
     *           minDate's year should be greater than or equal to 1601 since
     *           DateTimeFormatter only supports the range from 1601 to 30827.
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */
    public function get minDate():Date
    {
        return _minDate != null ? _minDate : MIN_DATE_DEFAULT;
    }
    
    /**
     *  @private
     */     
    public function set minDate(value:Date):void
    {
        if ((_minDate && value && _minDate.time == value.time)
            || (_minDate == null && value == null))
            return;
        
        _minDate = value;
        populateYearDataProvider = true;
        populateDateDataProvider = true;
        minDateChanged = true;
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  minuteStepSize
    //----------------------------------
    private var _minuteStepSize:int = 1;
    
    private var minuteStepSizeChanged:Boolean = false;
    
    /**
     *  Minute interval to be used when displaying minutes. Only
     *  applicable in TIME and DATE_AND_TIME modes. Valid values must
     *  be evenly divisible into 60; invalid values will revert to
     *  the default interval of 1. For example, a value of "15" will show
     *  the values 0, 15, 30, 45.
     *  
     *  @default 1
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     */     
    public function get minuteStepSize():int
    {
        return _minuteStepSize;
    }
    
    /**
     *  @private
     */     
    public function set minuteStepSize(value:int):void
    {
        if (value == _minuteStepSize)
            return;
        
        if (value <= 0 || 60 % value != 0)
            value = 1;
       
        _minuteStepSize = value;
        minuteStepSizeChanged = true;
        populateMinuteDataProvider = true;
        
        invalidateProperties();
    }
    
    //----------------------------------
    //  selectedDate
    //----------------------------------
    private var _selectedDate:Date = todayDate;
    
    // set to true initially so that lists will be set to right values on creation
    private var syncSelectedDate:Boolean = true;
    
    [Bindable(event="valueCommit")]
    /**
     *  Date that is currently selected in the DateSpinner control.
     *
     *  @default Current date when the DateSpinner was instantiated.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     * 
     */
    public function get selectedDate():Date
    {
        return _selectedDate;
    }
    
    /**
     *  @private
     */
    public function set selectedDate(value:Date):void
    {
        // no-op if null; there must always be a selectedDate
        if (value == null)
            value = todayDate;
        
        // short-circuit if no change
        if (value.time == _selectedDate.time)
            return;
        
        _selectedDate = value;
        syncSelectedDate = true;
        
        dispatchValueCommitEvent = true;

        invalidateProperties();
    }
    
    mx_internal function animateToSelectedDate(value:Date):void
    {
        // no-op if null; there must always be a selectedDate
        if (value == null)
            value = todayDate;
            
        // short-circuit if no change
        if (value.time == _selectedDate.time)
            return;

        selectedDate = value;
        
        useAnimationToSetSelectedDate = true;
    }
    
    //----------------------------------
    //  todayDate
    //----------------------------------

    mx_internal static var _todayDate:Date = null;

    /**
     *  @private
     *  Function to retrieve the current Date. Provided so that
     *  testing can override by setting the _todayDate variable.
     */
    private static function get todayDate():Date
    {
        if (_todayDate != null)
            return _todayDate;
        
        return new Date();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Overridden methods
    //
    //--------------------------------------------------------------------------
    
    override protected function attachSkin():void
    {
        super.attachSkin();
        
        displayModeChanged = true;
        
        invalidateProperties();
    }    

    override protected function commitProperties():void
    {
        super.commitProperties();
        
        // TODO: CHECK ON THIS ASSUMPTION
        // TODO: Jason says this is wrong; just use styleName = DateSpinner to link styles
        //       but having trouble getting that to work
        var localeStr:String = getStyle("locale");
        if (refreshDateTimeFormatter)
        {
            if (localeStr)
            {
                dateTimeFormatterEx.setStyle("locale", localeStr);
                dateTimeFormatter.setStyle("locale", localeStr);
            }
            else
            {
                dateTimeFormatterEx.clearStyle("locale");
                dateTimeFormatter.clearStyle("locale");
            }
            
            use24HourTime = dateTimeFormatterEx.getUse24HourFlag();
            refreshDateTimeFormatter = false;
        }
        
        // ==================================================
        // switch out lists if the display mode changed
        
        if (displayModeChanged)
        {
            setupDateItemLists();
            
            displayModeChanged = false;
            syncSelectedDate = true;
        }

        // ==================================================
        // populate the lists with the appropriate data providers
        
        populateDateItemLists(localeStr);
        
        // ==================================================
        
        // correct any integrity violations
        if (minDateChanged || maxDateChanged || syncSelectedDate || minuteStepSizeChanged)
        {        
            // check min <= max
            if (minDate.time > maxDate.time)
            {
                // note assumption here that we're not using the defaults since they
                // should always maintain minDate < maxDate integrity
                
                // correct min/max dates, one day apart
                if (!maxDateChanged)
                    _minDate.time = _maxDate.time - MS_IN_DAY; // min date was changed past max
                else
                    _maxDate.time = _minDate.time + MS_IN_DAY; // max date was changed past min
            }
            
            var origSelectedDate:Date = new Date(_selectedDate.time);
            
            // check minDate <= selectedDate <= maxDate
            if (!selectedDate || selectedDate.time < minDate.time)
            {
                _selectedDate = new Date(minDate.time);
            }
            else if (selectedDate.time > maxDate.time)
            {
                _selectedDate = new Date(maxDate.time);
            }
            
            minDateChanged = false;
            maxDateChanged = false;
            
            if (minuteStepSizeChanged)
            {
                // verify minutes are a multiple of minuteStepSize
                if (minuteList && ((selectedDate.minutes % minuteStepSize) != 0))
                {
                    _selectedDate.minutes -= (selectedDate.minutes % minuteStepSize);
                    
                    // last adjustment to make sure we didn't accidentally go below minDate
                    if (selectedDate.time < minDate.time)
                        _selectedDate.minutes += minuteStepSize;
                    
                    // make sure to use animation for this
                    useAnimationToSetSelectedDate = true;
                }
                
                minuteStepSizeChanged = false;
            }
            
            if (origSelectedDate.time != _selectedDate.time)
                dispatchValueCommitEvent = true;

            disableInvalidSpinnerValues(selectedDate);
            
            syncSelectedDate = true;
        }
        
        // ==================================================
        // update selections on the lists if necessary
        if (syncSelectedDate)
        {
            updateListsToSelectedDate(useAnimationToSetSelectedDate);
            syncSelectedDate = false;
            
            if (dispatchChangeEvent || dispatchValueCommitEvent)
            {
                // dispatch the events: now or after animation?
                if (useAnimationToSetSelectedDate)
                {
                    // we animated the list ourselves; wait for lists
                    // to report VALUE_COMMIT before dispatching our events
                    var numEls:int = listContainer.numElements;
                    var sl:SpinnerList;
                    for (var elIdx:int = 0; elIdx < numEls; elIdx++)
                    {
                        sl = listContainer.getElementAt(elIdx) as SpinnerList;
                        sl.addEventListener(FlexEvent.VALUE_COMMIT, waitForSpinnerListValueCommit_handler);
                    }
                }
                else
                {
                    // dispatch our events immediately
                    dispatchSelectedDateChangedEvents();
                }
            }
        }

        // reset flags
        useAnimationToSetSelectedDate = false;
    }
    
    override public function styleChanged(styleProp:String):void
    {
        super.styleChanged(styleProp);
        
        // if locale changed, all date item formats need to be regenerated
        if (styleProp == "locale")
        {
            displayModeChanged = true; // order of lists may be different with new locale
            
            populateYearDataProvider = true;
            populateMonthDataProvider = true;
            populateDateDataProvider = true;
            populateHourDataProvider = true;
            populateMinuteDataProvider = true;
            populateMeridianDataProvider = true;
            
            refreshDateTimeFormatter = true;
            
            syncSelectedDate = true;
            
            longestDateItem = null;
            longestYearItem = null;
            
            invalidateProperties();
        }
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Create a list object for the specified date part.
     * 
     *  @param datePart Use date part constants, e.g. YEAR_ITEM.
     * 
     *  @langversion 3.0
     *  @playerversion AIR 3
     *  @productversion Flex 4.5.2
     * 
     */
    protected function createDateItemList(datePart:String, itemIndex:int, itemCount:int):SpinnerList
    {
        // itemIndex and itemCount not used yet; will be used when localization support
        // is put in place, e.g.
        // if itemIndex == 0, align as first column,
        // if itemIndex == itemCount - 1, align as last column
        
        var s:SpinnerList = SpinnerList(createDynamicPartInstance("dateItemList"));
        s.percentHeight = 100;
        return s;
    }
    
    /**
     *  @private
     *  Sets up the date item lists based on the current mode. Clears pre-existing lists.
     */    
    private function setupDateItemLists():void
    {
        // an array of the list and position objects that will be sorted by position
        var fieldPositionObjArray:ArrayCollection = new ArrayCollection();
        var listSort:ISort = new Sort();
        listSort.fields = [new SortField("position")];
        fieldPositionObjArray.sort = listSort;
        
        // clean out the container and all existing lists
        // they may be in different positions, which will affect how they
        // need to be (re)created
        cleanContainer();
        
        var fieldPosition:int = 0;
        var listItem:Object;
        var tempList:SpinnerList;
        var numItems:int;
        
        // configure the correct lists to use
        if (displayMode == DateSelectorDisplayMode.TIME ||
            displayMode == DateSelectorDisplayMode.DATE_AND_TIME)
        {
            fieldPositionObjArray.addItem(generateFieldPositionObject(HOUR_ITEM, dateTimeFormatterEx.getHourPosition()));
            fieldPositionObjArray.addItem(generateFieldPositionObject(MINUTE_ITEM, dateTimeFormatterEx.getMinutePosition()));
            
            if (displayMode == DateSelectorDisplayMode.DATE_AND_TIME)
                fieldPositionObjArray.addItem(generateFieldPositionObject(DATE_ITEM, dateTimeFormatterEx.getMonthPosition()));
            
            if (!use24HourTime)
                fieldPositionObjArray.addItem(generateFieldPositionObject(MERIDIAN_ITEM, dateTimeFormatterEx.getAmPmPosition()));
            
            // sort fieldPosition objects by position               
            fieldPositionObjArray.refresh();
            
            numItems = fieldPositionObjArray.length;
            
            for each (listItem in fieldPositionObjArray)
            {
                switch(listItem.dateItem)
                {
                    case HOUR_ITEM:
                    {
                        hourList = createDateItemList(HOUR_ITEM, fieldPosition++, numItems);
                        tempList = hourList;
                        break;
                    }
                    case MINUTE_ITEM:
                    {
                        minuteList = createDateItemList(MINUTE_ITEM, fieldPosition++, numItems);
                        tempList = minuteList;
                        break;
                    }
                    case MERIDIAN_ITEM:
                    {
                        meridianList = createDateItemList(MERIDIAN_ITEM, fieldPosition++, numItems);
                        tempList = meridianList;
                        break;
                    }   
                    case DATE_ITEM:
                    {
                        dateList = createDateItemList(DATE_ITEM, fieldPosition++, numItems);
                        dateList.wrapElements = false;
                        tempList = dateList;
                        break;
                    }
                }
                if (tempList && listContainer)
                {
                    tempList.addEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
                    listContainer.addElement(tempList);
                }
            }
        }
        else // default case: DATE mode
        {
            fieldPositionObjArray.addItem(generateFieldPositionObject(MONTH_ITEM, dateTimeFormatterEx.getMonthPosition()));
            fieldPositionObjArray.addItem(generateFieldPositionObject(DATE_ITEM, dateTimeFormatterEx.getDayOfMonthPosition()));
            fieldPositionObjArray.addItem(generateFieldPositionObject(YEAR_ITEM, dateTimeFormatterEx.getYearPosition()));
            
            // sort fieldPosition objects by position 
            fieldPositionObjArray.refresh();
            
            numItems = fieldPositionObjArray.length;
            
            for each (listItem in fieldPositionObjArray)
            {
                switch(listItem.dateItem)
                {
                    case MONTH_ITEM:
                    {
                        monthList = createDateItemList(MONTH_ITEM, fieldPosition++, numItems);
                        tempList = monthList;
                        break;
                    }
                    case DATE_ITEM:
                    {
                        dateList = createDateItemList(DATE_ITEM, fieldPosition++, numItems);
                        tempList = dateList;
                        break;
                    }
                    case YEAR_ITEM:
                    {
                        yearList = createDateItemList(YEAR_ITEM, fieldPosition++, numItems);
                        yearList.wrapElements = false;
                        tempList = yearList;
                        break;
                    }   
                }
                if (tempList && listContainer)
                {
                    tempList.addEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
                    listContainer.addElement(tempList);                    
                }
            }
        }
    }
    
    /**
     *  Populate the currently existing date item lists with correct data providers using the
     *  provided locale to format the 
     */    
    private function populateDateItemLists(localeStr:String):void
    {
        var today:Date = todayDate;
        
        // populate lists that are being shown
        if (yearList && populateYearDataProvider)
        {
            yearList.dataProvider = new YearProvider(localeStr, minDate.fullYear,
                maxDate.fullYear, today, getStyle("accentColor"));
            
            // set size to longest string
            if (!longestYearItem)
                longestYearItem = findLongestYearItem();
            
            yearList.typicalItem = longestYearItem;
        }
        if (monthList && populateMonthDataProvider)
        {
            monthList.dataProvider = generateMonths(today);
            
            // set size
            monthList.typicalItem = getLongestLabel(monthList.dataProvider);
        }
        if (dateList && populateDateDataProvider)
        {
            if (displayMode == DateSelectorDisplayMode.DATE_AND_TIME)
            {
                dateList.dataProvider = new DateAndTimeProvider(localeStr, minDate, maxDate,
                    today, getStyle("accentColor"));
                
                // set size to longest string
                if (!longestDateItem)
                    longestDateItem = findLongestDateItem();
                
                dateList.typicalItem = longestDateItem;
            }
            else
            {
                dateList.dataProvider = generateMonthOfDates(today);
                
                // set size to width of longest visible value
                dateList.typicalItem = getLongestLabel(dateList.dataProvider);
            }
        }
        if (hourList && populateHourDataProvider)
        {
            hourList.dataProvider = generateHours(use24HourTime);
            hourList.typicalItem = getLongestLabel(hourList.dataProvider);
        }
        if (minuteList && populateMinuteDataProvider)
        {
            minuteList.dataProvider = generateMinutes();
            minuteList.typicalItem = getLongestLabel(minuteList.dataProvider);
        }
        if (meridianList && populateMeridianDataProvider)
        {
            var amObject:Object = generateAmPm(AM);
            var pmObject:Object = generateAmPm(PM);
            meridianList.dataProvider = new ArrayCollection([amObject, pmObject]);
            meridianList.typicalItem = getLongestLabel(meridianList.dataProvider);
        }

        // reset all flags
        populateYearDataProvider = false;
        populateMonthDataProvider = false;
        populateDateDataProvider = false;
        populateHourDataProvider = false;
        populateMinuteDataProvider = false;
        populateMeridianDataProvider = false;
    }
    
    // set the selected index on the SpinnerList. use animation only if requested
    private function goToIndex(list:SpinnerList, newIndex:int, useAnimation:Boolean):void
    {
        // don't do anything if it's already on that index
        if (list.selectedIndex == newIndex)
            return;
        
        if (useAnimation)
        {
            list.animateToSelectedIndex(newIndex);
            listsBeingAnimated[list] = true;
        }
        else
        {
            list.selectedIndex = newIndex;
        }
    }
    
    // generate objects to populate a SpinnerList with months
    private function generateMonths(today:Date):IList
    {
        var ac:ArrayCollection = new ArrayCollection();
        var todayMonth:int = today.getMonth();
        
        var monthNames:Vector.<String> = dateTimeFormatterEx.getMonthNames();
        
        for (var i:Number = 0; i < 12; i++)
        {
            var item:Object = generateDateItemObject(monthNames[i], i);
            
            if (i == todayMonth)
                item["accentColor"] = getStyle("accentColor");
                
            ac.addItem(item);
        }
        
        return ac;
    }
    
    // generate objects to populate a SpinnerList with dates, e.g. "1, 2, 3, ... 31"
    private function generateMonthOfDates(today:Date):IList
    {
        var ac:ArrayCollection = new ArrayCollection();
        var todayDate:int = today.getDate();
        
        dateTimeFormatter.dateTimePattern = dateTimeFormatterEx.getDayOfMonthPattern();
        
        // guarantee 31 days in the month
        dateObj.time = JAN1980_IN_MS;
        
        for (var i:int = 1; i <= 31; i++)
        {
            dateObj.date = i;
            var item:Object = generateDateItemObject(dateTimeFormatter.format(dateObj), i);

            if (i == todayDate)
                item["accentColor"] = getStyle("accentColor");
        
            ac.addItem(item);
        }
        
        return ac;
    }
    
    // generate hour objects for a SpinnerList
    private function generateHours(use24HourTime:Boolean):IList
    {
        var ac:ArrayCollection = new ArrayCollection();
        
        var minHour:int = use24HourTime ? 0 : 1;
        var maxHour:int = use24HourTime ? 23 : 12;
        
        dateTimeFormatter.dateTimePattern = dateTimeFormatterEx.getHourPattern();
        
        for (var i:int = minHour; i <= maxHour; i++)
        {
            dateObj.hours = i;
            ac.addItem( generateDateItemObject(dateTimeFormatter.format(dateObj), i) );
        }
        
        return ac;
    }
    
    private function generateMinutes():IList
    {
        var ac:ArrayCollection = new ArrayCollection();
        
        dateTimeFormatter.dateTimePattern = dateTimeFormatterEx.getMinutePattern();
        
        for (var i:int = 0; i <= 59; i += minuteStepSize)
        {
            dateObj.minutes = i;
            ac.addItem( generateDateItemObject(dateTimeFormatter.format(dateObj), i) );
        }
        
        return ac;
    }
    
    private function generateAmPm(value:String):Object
    {
        dateTimeFormatter.dateTimePattern = dateTimeFormatterEx.getAmPmPattern();
        
        dateObj.hours = (value == AM)? 1 : 13;
        
        return generateDateItemObject(dateTimeFormatter.format(dateObj), value);
    }

    // TODO: possibly optimize usages and remove this function
    private function findDateItemIndexInDataProvider(item:Number, dataProvider:IList):int
    {
        for (var i:int = 0; i < dataProvider.length; i++)
        {
            if (dataProvider.getItemAt(i).data == item)
                return i;
        }
        return -1;
    }
    
    private function getLongestLabel(list:IList):Object
    {
        var idx:int = -1;
        var maxWidth:Number = 0;
        var labelWidth:Number;
        for (var i:int = 0; i < list.length; i++)
        {
            labelWidth = measureText(list[i].label).width;
            if (labelWidth > maxWidth)
            {
                maxWidth = labelWidth;
                idx = i;
            }
        }
        if (idx != -1)
            return list.getItemAt(idx);
        
        return null;
    }
    
    private function updateListsToSelectedDate(useAnimation:Boolean):void
    {
        var newIndex:int;
        if (yearList)
        {
            dateTimeFormatter.dateTimePattern = dateTimeFormatterEx.getYearPattern();
            newIndex = yearList.dataProvider.getItemIndex( generateDateItemObject(dateTimeFormatter.format(selectedDate), selectedDate.fullYear) );
            goToIndex(yearList, newIndex, useAnimation);
        }
        
        if (monthList)
            goToIndex(monthList, selectedDate.month, useAnimation);
        
        if (dateList)
        {
            if (displayMode == DateSelectorDisplayMode.DATE)
            {
                goToIndex(dateList, selectedDate.date - 1, useAnimation);
            }
            else // DATE_AND_TIME mode
            {
                newIndex = dateList.dataProvider.getItemIndex( generateDateItemObject(dayMonthDateFormatter.format(selectedDate), selectedDate.time) );
                goToIndex(dateList, newIndex, useAnimation);
            }
        }
        if (hourList)
        {
            // TODO: double-check the math
            newIndex = use24HourTime ? selectedDate.hours : (selectedDate.hours + 11) % 12;
            goToIndex(hourList, newIndex, useAnimation);
        }
        if (minuteList)
        {
            // TODO: calculate instead of iterate?
            newIndex = findDateItemIndexInDataProvider(selectedDate.minutes, minuteList.dataProvider);
            goToIndex(minuteList, newIndex, useAnimation);
        }
        if (!use24HourTime && meridianList)
        {
            newIndex = selectedDate.hours < 12 ? 0 : 1;
            goToIndex(meridianList, newIndex, useAnimation);
        }
    }
    
    // modify existing date item spinner list data providers to mark
    // as disabled any combinations that could result by moving one spinner
    // where the resulting new date would be invalid, either by definition
    // (e.g. Apr 31 is not a valid date) or by limitation (e.g. outside of the
    // range defined by minDate and maxDate)
    private function disableInvalidSpinnerValues(thisDate:Date):void
    {
        var tempDate:Date;
        
        // disable dates in spinners that are invalid (e.g. Apr 31) or fall outside
        // of the min/max date range
        if (dateList)
        {
            if (displayMode == DateSelectorDisplayMode.DATE)
            {
                var listData:IList = dateList.dataProvider;
                tempDate = new Date(thisDate.time);
                
                // run through the entire list of dates and set enabled flags as necessary
                var cd:CalendarDate = new CalendarDate(thisDate);
                var numDaysInMonth:int = cd.numDaysInMonth;
                var listLength:int = listData.length;
                
                var minMonthMatch:Boolean = (tempDate.fullYear == minDate.fullYear
                    && tempDate.month == minDate.month);
                var maxMonthMatch:Boolean = (tempDate.fullYear == maxDate.fullYear
                    && tempDate.month == maxDate.month);
                
                for (var i:int = 0; i < listLength; i++)
                {
                    var curObj:Object = listData[i];
                    
                    // is the date invalid for this month?
                    var newEnabledValue:Boolean = i < numDaysInMonth;
                    
                    if (newEnabledValue)
                    {
                        // test for outside min/max range
                        tempDate.date = curObj.data;
                        
                        if (minMonthMatch && tempDate.date < minDate.date)
                            newEnabledValue = false;
                        if (maxMonthMatch && tempDate.date > maxDate.date)
                            newEnabledValue = false;
                    }
                    
                    // note this is where future support for more complex unselectable dates could be added
                    
                    if (curObj[SpinnerList.ENABLED_PROPERTY_NAME] != newEnabledValue)
                    {
                        var o:Object = generateDateItemObject(curObj.label, curObj.data, newEnabledValue);
                        o["accentColor"] = curObj["accentColor"];
                        listData[i] = o;
                    }
                }
            }
        }
        
        // disable months that fall outside of the min/max dates
        if (monthList && displayMode == DateSelectorDisplayMode.DATE)
        {
            tempDate = new Date(thisDate.time);
            
            listData = monthList.dataProvider;
            for (i = 0; i < 12; i++)
            {
                newEnabledValue = true;
                
                tempDate.month = i;
                if ((tempDate.fullYear == minDate.fullYear
                    && tempDate.month < minDate.month) ||
                    (tempDate.fullYear == maxDate.fullYear
                        && tempDate.month > maxDate.month))
                    newEnabledValue = false;
                
                curObj = listData[i];
                if (curObj[SpinnerList.ENABLED_PROPERTY_NAME] != newEnabledValue)
                {
                    o = generateDateItemObject(curObj.label, curObj.data, newEnabledValue);
                    o["accentColor"] = curObj["accentColor"];
                    listData[i] = o;
                }
            }
        }

        
        // disable hours that fall outside of the min/max dates
        if (hourList && (displayMode == DateSelectorDisplayMode.TIME || displayMode == DateSelectorDisplayMode.DATE_AND_TIME))
        {
            tempDate = new Date(thisDate.time);
            listData = hourList.dataProvider;
            listLength = listData.length;
            
            var minDateMatch:Boolean = (tempDate.fullYear == minDate.fullYear
                && tempDate.month == minDate.month
                && tempDate.date == minDate.date);
            var maxDateMatch:Boolean = (tempDate.fullYear == maxDate.fullYear
                && tempDate.month == maxDate.month
                && tempDate.date == maxDate.date);
            
            for (i = 0; i < listLength; i++)
            {
                curObj = listData[i];
                
                newEnabledValue = true;
                 
                if (!use24HourTime)
                    tempDate.hours = (i + 1) % 12 + ((selectedDate.hours >= 12)? 12 : 0);
                else
                    tempDate.hours = i;
                
                if (minDateMatch && tempDate.hours < minDate.hours)
                    newEnabledValue = false;
                
                if (maxDateMatch && tempDate.hours > maxDate.hours)
                    newEnabledValue = false;
                
                if (curObj[SpinnerList.ENABLED_PROPERTY_NAME] != newEnabledValue)
                {
                    o = generateDateItemObject(curObj.label, curObj.data, newEnabledValue);
                    o["accentColor"] = curObj["accentColor"];
                    listData[i] = o;
                }
            }
        }
        
        // disable minutes that fall outside of the min/max dates
        if (minuteList && (displayMode == DateSelectorDisplayMode.TIME || displayMode == DateSelectorDisplayMode.DATE_AND_TIME))
        {
            tempDate = new Date(thisDate.time);
            listData = minuteList.dataProvider;
            listLength = listData.length;
            
            var minHourMatch:Boolean = (tempDate.fullYear == minDate.fullYear
                && tempDate.month == minDate.month
                && tempDate.date == minDate.date
                && tempDate.hours == minDate.hours);
            var maxHourMatch:Boolean = (tempDate.fullYear == maxDate.fullYear
                && tempDate.month == maxDate.month
                && tempDate.date == maxDate.date
                && tempDate.hours == maxDate.hours);
            
            for (i = 0; i < listLength; i++)
            {
                curObj = listData[i];
                
                newEnabledValue = true;
                
                tempDate.minutes = curObj.data;
               
                if (minHourMatch && tempDate.minutes < minDate.minutes)
                    newEnabledValue = false;
                
                if (maxHourMatch && tempDate.minutes > maxDate.minutes)
                    newEnabledValue = false;
                
                if (curObj[SpinnerList.ENABLED_PROPERTY_NAME] != newEnabledValue)
                {
                    o = generateDateItemObject(curObj.label, curObj.data, newEnabledValue);
                    o["accentColor"] = curObj["accentColor"];
                    listData[i] = o;
                }
            }
        }
    }
    
    // clean out the container: remove all elements, detach event listeners, null out references
    private function cleanContainer():void
    {
        if (listContainer)
            listContainer.removeAllElements();
        
        if (yearList)
        {
            yearList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
            yearList = null;
        }
        if (monthList)
        {
            monthList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
            monthList = null;
        }
        if (dateList)
        {
            dateList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
            dateList = null;
        }
        if (hourList)
        {
            hourList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
            hourList = null;
        }
        if (minuteList)
        {
            minuteList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
            minuteList = null;
        }
        if (meridianList)
        {
            meridianList.removeEventListener(IndexChangeEvent.CHANGE, dateItemList_changeHandler);
            meridianList = null;
        }
    }
    
    // convenience method to generate the standard object format for data in the list dataproviders
    private function generateDateItemObject(label:String, data:*, enabled:Boolean = true):Object
    {
        var obj:Object = { label:label, data:data };
        obj[SpinnerList.ENABLED_PROPERTY_NAME] = enabled;
        return obj;
    }

    // generate the fieldPosition object that contains the date part name and position based on locale
    private function generateFieldPositionObject(datePart:String, position:int):Object
    {
        var obj:Object = { dateItem:datePart, position:position };
        return obj;
    }
    
    // returns true if any of the lists are currently animating
    private function get spinnersAnimating():Boolean
    {
        if (!listContainer)
            return false;
        
        var len:int = listContainer.numElements;
        for (var i:int = 0; i < len; i++)
        {
            var list:SpinnerList = listContainer.getElementAt(i) as SpinnerList;
            // return true as soon as we have one list still in touch interaction
            if (list && list.scroller && list.scroller.inTouchInteraction)
                return true;
        }
        return false;
    }
    
    // identify the dateList item that has the longest width in DATE_AND_TIME mode
    private function findLongestDateItem():Object
    {
        updateDayMonthDateFormatter();
        
        var labelWidth:Number = -1;
        var maxWidth:Number = 0;
        dateObj.date = 1;
        dateObj.hours = 11;
        dateObj.minutes = 0;
        dateObj.seconds = 0;
        dateObj.milliseconds = 0;
        
        // 1) find the longest month
        var longestMonth:int = 0;
        dateTimeFormatter.dateTimePattern = dayMonthDateFormatter.getMonthPattern();
        
        for (var month:int = 0; month < 12; month++)
        {
            dateObj.month = month;
           
            labelWidth = measureText(dateTimeFormatter.format(dateObj)).width;
            if (labelWidth > maxWidth)
            {
                maxWidth = labelWidth;
                longestMonth = month;
            }
        }
        
        dateObj.month = longestMonth;
        
        // 2) find the longest date
        var longestDate:int = 0;
        var longestDateWidth:Number;
        maxWidth = 0;
        updateNumberFormatter();
        
        for (var date:int = 1; date <= 28; date++)
        {
            labelWidth = measureText(numberFormatter.format(date)).width;
            if (labelWidth > maxWidth)
            {
                maxWidth = labelWidth;
                longestDate = date;
            }
        }
        
        longestDateWidth = maxWidth;
        dateObj.date = longestDate;
        
        // 3) find the longest date item
        var longestDateItemObj:Object = dateList.dataProvider.getItemAt(0);
        var formattedDateStr:String;
        maxWidth = 0;
        
        for (var year:int = 2000; year <= 2010; year++)
        {
            dateObj.fullYear = year;
            formattedDateStr = dayMonthDateFormatter.format(dateObj);
            labelWidth = measureText(formattedDateStr).width;
            if (labelWidth > maxWidth)
            {
                maxWidth = labelWidth;
                longestDateItemObj = generateDateItemObject(formattedDateStr, dateObj.time);
            }
        }
        
        // 4) compare to date 29, 30, 31
        var trueLongestDate:int = longestDate;
        maxWidth = longestDateWidth;
 
        for (date = 29; date <= 31; date++)
        {
            labelWidth = measureText(numberFormatter.format(date)).width;
            if (labelWidth > maxWidth)
            {
                maxWidth = labelWidth;
                trueLongestDate = date;
            }
        }
        
        if (trueLongestDate != longestDate)
        {
            formattedDateStr = String(longestDateItemObj.label);
            
            // replace all the occurrence of the previous longest date to the true longest date
            longestDateItemObj.label = String(longestDateItemObj.label).replace(new RegExp(numberFormatter.format(longestDate), "g"), 
                numberFormatter.format(trueLongestDate));
            
            // since the result can be wrong date such as "Wed, Feb 31," assign null to data
            longestDateItemObj.data = null;
        }
        
        return longestDateItemObj;
    }
    
    // identify the yearList item that has the longest width in DATE mode 
    // the range of year should be from 1601 to 9999
    private function findLongestYearItem():Object
    {
        // instantiate the number formatter and set its locale to the DateSpinner's locale
        // and refresh longestDigitArray to pick the longest digit in a current locale format.
        updateNumberFormatter();
        
        // generate the longest width year
        var longestYear:int = getLongestDigit(1) * 1000;
        
        // if the first (left-most) digit is greater than 1, then the rest digit is just the longest digit of 0~9.
        if (getLongestDigit(1) > 1)
            longestYear += getLongestDigit() * 111;
        
        // if the first digit is 1, then the second digit should be greater than or equal to
        // (1) 7 if none of last two digits is 0.
        // (2) 6 if both last two digits are 0.
        else
            longestYear += ((getLongestDigit() == 0)? getLongestDigit(7) : getLongestDigit(6)) * 100 +
                getLongestDigit() * 10 + getLongestDigit();
         
        dateObj.fullYear = longestYear;
        dateTimeFormatter.dateTimePattern = dateTimeFormatterEx.getYearPattern();
        return generateDateItemObject(dateTimeFormatter.format(dateObj), longestYear);
    }
    
    // return the longest digit between min and 9, inclusive
    // call updateNumberFormatter() before calling this function to refresh longestDigitArray
    private function getLongestDigit(min:int = 0):int
    {
        var longestDigit:int = longestDigitArray[min];
        var labelWidth:Number = -1;
        var maxWidth:Number = 0;
        
        if (longestDigit == -1)
        {
            for (var i:int = min; i < 10; i++)
            {
                labelWidth = measureText(numberFormatter.format(i)).width;
                if (labelWidth > maxWidth)
                {
                    maxWidth = labelWidth;
                    longestDigit = i;
                }
            }
            
            longestDigitArray[min] = longestDigit;
        }
        
        return longestDigit;
    }
    
    // instantiate the number formatter and update its locale property
    private function updateNumberFormatter():void
    {
        if(!numberFormatter)
            numberFormatter = new NumberFormatter();
        
        // reset to -1
        for (var i:int = 0; i < longestDigitArray.length; i++) 
            longestDigitArray[i] = -1;
        
        var localeStr:String = getStyle("locale");
        if (localeStr)
            numberFormatter.setStyle("locale", localeStr);
        else
            numberFormatter.clearStyle("locale");
    }
    
    // instantiate the dayMonthDateFormatter and update its locale property
    private function updateDayMonthDateFormatter():void
    {
        if (!dayMonthDateFormatter)
        {
            dayMonthDateFormatter = new DateTimeFormatterEx();
            dayMonthDateFormatter.dateTimeSkeletonPattern = DateTimeFormatterEx.DATESTYLE_MMMEEEd;
        }
        
        var localeStr:String = getStyle("locale");
        if (localeStr)
            dayMonthDateFormatter.setStyle("locale", localeStr);
        else
            dayMonthDateFormatter.clearStyle("locale");
    }
    
    // used to delay the dispatch of change events from this DateSpinner until
    // the underlying SpinnerLists have stopped animating (signified by
    // a VALUE_COMMIT event)
    private function waitForSpinnerListValueCommit_handler(event:FlexEvent):void
    {
        // if listsBeingAnimated contains event.target remove it
        if (listsBeingAnimated[event.target])
        {
            delete listsBeingAnimated[event.target];
        }

        // if we're still waiting on any lists, don't dispatch yet
        for (var key:Object in listsBeingAnimated)
        {
            return;
        }
        
        // if no more in listsBeingAnimated, dispatch
        dispatchSelectedDateChangedEvents();
        
        // clean up
        var numEls:int = listContainer.numElements;
        var sl:SpinnerList;
        for (var elIdx:int = 0; elIdx < numEls; elIdx++)
        {
            sl = listContainer.getElementAt(elIdx) as SpinnerList;
            sl.removeEventListener(FlexEvent.VALUE_COMMIT, waitForSpinnerListValueCommit_handler);
        }
    }
    
    // dispatch the appropriate events when selectedDate changed
    private function dispatchSelectedDateChangedEvents():void
    {
        if (dispatchChangeEvent)
        {
            if (hasEventListener(Event.CHANGE))
                dispatchEvent(new Event(Event.CHANGE));

            dispatchChangeEvent = false;
        }
        if (dispatchValueCommitEvent)
        {
            if (hasEventListener(FlexEvent.VALUE_COMMIT))
                dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
                        
            dispatchValueCommitEvent = false;
        }
    }
    
    //----------------------------------------------------------------------------------------------
    //
    //  Event handlers
    //
    //----------------------------------------------------------------------------------------------
    /**
     *  Handles changes in the underlying SpinnerLists; applies them to the selectedDate
     * @param event
     * 
     */ 
    private function dateItemList_changeHandler(event:IndexChangeEvent):void
    {
        if (spinnersAnimating)
        {
            // don't commit any changes until all spinners have come to a stop
            return;
        }
        
        // start with the previous selectedDate
        var newDate:Date = new Date(selectedDate.time);

        var tempDate:Date;
        var cd:CalendarDate;
        
        var numLists:int = listContainer.numElements;
        var currentList:SpinnerList;
        
        var dateRolledBack:Boolean = false;
        
        // loop through all lists in the container and adjust selectedDate to their values
        for (var i:int = 0; i < numLists; i++)
        {
            currentList = listContainer.getElementAt(i) as SpinnerList;
            var newValue:* = currentList.selectedItem;
            
            switch (currentList)
            {
                case monthList:
                    // rollback date if past end of month
                    if (dateList)
                    {
                        tempDate = new Date(selectedDate.fullYear, newValue.data, 1);
                        cd = new CalendarDate(tempDate);
                        if (dateList.selectedItem.data > cd.numDaysInMonth)
                        {
                            newDate.date = cd.numDaysInMonth;
                            dateRolledBack = true;
                        }
                    }
                    newDate.month = newValue.data;
                    break;
                case dateList:
                    // for DATE_AND_TIME mode data is a Date.time value
                    if (displayMode == DateSelectorDisplayMode.DATE_AND_TIME)
                    {
                        var spinnerDate:Date = new Date(newValue.data);
                        newDate.fullYear = spinnerDate.fullYear;
                        newDate.month = spinnerDate.month;
                        newDate.date = spinnerDate.date;
                    }
                    else if (!dateRolledBack) // don't tamper with date if we already rolled it back
                    {
                        newDate.date = newValue.data;
                    }
                    break;
                case yearList:
                    // rollback date if past end of month
                    if (dateList)
                    {
                        tempDate = new Date(newValue.data, selectedDate.month, 1);
                        cd = new CalendarDate(tempDate);
                        if (dateList.selectedItem.data > cd.numDaysInMonth)
                        {
                            newDate.date = cd.numDaysInMonth;
                            dateRolledBack = true;
                        }
                    }
                    newDate.fullYear = newValue.data;
                    break;
                case hourList:
                    if (use24HourTime)
                    {
                        newDate.hours = newValue.data;
                    }
                    else
                    {
                        // a little trickier; need to convert to 24-hour time
                        // assumption is that if !use24HourTime, meridianList exists
                        newDate.hours = ((newValue.data + 12) % 12) + (meridianList.selectedItem.data == "pm" ? 12 : 0); 
                    }
                    break;
                case minuteList:
                    newDate.minutes = newValue.data;
                    break;
                case meridianList:
                    if (newValue.data == "am" && newDate.hours > 11)
                        newDate.hours -= 12;
                    else if (newValue.data == "pm" && newDate.hours < 12)
                        newDate.hours += 12;
                    break;
                default:
                    // unknown list; don't know how to handle
                    break;
            }
        }

        dispatchChangeEvent = true;
        if (dateRolledBack)
            animateToSelectedDate(newDate);
        else
            selectedDate = newDate;
    }
}
}
