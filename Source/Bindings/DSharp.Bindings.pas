(*
  Copyright (c) 2011, Stefan Glienke
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  - Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  - Neither the name of this library nor the names of its contributors may be
    used to endorse or promote products derived from this software without
    specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
*)

unit DSharp.Bindings;

interface

uses
  Classes,
  DSharp.Bindings.Collections,
  DSharp.Bindings.Notifications,
  DSharp.Collections,
  DSharp.Core.Collections,
  DSharp.Core.DataConversion,
  DSharp.Core.Editable,
  DSharp.Core.Events,
  DSharp.Core.Expressions,
  DSharp.Core.NotificationHandler,
  DSharp.Core.Validations,
  Rtti,
  SysUtils;

type
  TBindingMode = (bmOneWay, bmTwoWay, bmOneWayToSource, bmOneTime);

const
  BindingModeDefault = bmTwoWay;

type
  BindingAttribute = class(TCustomAttribute)
  private
    FBindingMode: TBindingMode;
    FSourcePropertyName: string;
    FTargetPropertyName: string;
  public
    constructor Create(const ASourcePropertyName, ATargetPropertyName: string;
      ABindingMode: TBindingMode = BindingModeDefault);
    property BindingMode: TBindingMode read FBindingMode;
    property SourcePropertyName: string read FSourcePropertyName;
    property TargetPropertyName: string read FTargetPropertyName;
  end;

  TBindingGroup = class;

  TBindingBase = class abstract(TCollectionItem,
    INotifyPropertyChanged, IValidatable)
  private
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function GetUpdating: Boolean;
  protected
    FActive: Boolean;
    FBindingGroup: TBindingGroup;
    FBindingMode: TBindingMode;
    FConverter: IValueConverter;
    FEnabled: Boolean;
    FManaged: Boolean;
    FNotificationHandler: TNotificationHandler<TBindingBase>;
    FNotifyOnTargetUpdated: Boolean;
    FOnPropertyChanged: Event<TPropertyChangedEvent>;
    FOnTargetUpdated: TPropertyChangedEvent;
    FOnValidation: Event<TValidationEvent>;
    FPreventFocusChange: Boolean;
    FTarget: TObject;
    FTargetProperty: IMemberExpression;
    FTargetPropertyName: string;
    FTargetUpdateTrigger: TUpdateTrigger;
    FUpdateCount: Integer;
    FValidatesOnDataErrors: Boolean;
    FValidationErrors: IList<IValidationResult>;
    FValidationRules: IList<IValidationRule>;
    class var DataErrorValidationRule: IValidationRule;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure CompileExpressions; virtual; abstract;
    procedure DoPropertyChanged(const APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged);
    procedure DoTargetPropertyChanged(ASender: TObject;
      APropertyName: string; AUpdateTrigger: TUpdateTrigger); virtual; abstract;
    procedure DoTargetUpdated(ASender: TObject; APropertyName: string;
      AUpdateTrigger: TUpdateTrigger);
    procedure DoValidationErrorsChanged(Sender: TObject;
      const Item: IValidationResult; Action: TCollectionChangedAction);
    procedure DoValidationRulesChanged(Sender: TObject;
      const Item: IValidationRule; Action: TCollectionChangedAction);
    function GetOnPropertyChanged: IEvent<TPropertyChangedEvent>;
    function GetOnValidation: IEvent<TValidationEvent>;
    function GetValidationErrors: IList<IValidationResult>;
    function GetValidationRules: IList<IValidationRule>;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); virtual;
    procedure SetActive(const Value: Boolean);
    procedure SetBindingGroup(const Value: TBindingGroup);
    procedure SetBindingMode(const Value: TBindingMode); virtual;
    procedure SetConverter(const Value: IValueConverter);
    procedure SetEnabled(const Value: Boolean);
    procedure SetTarget(const Value: TObject);
    procedure SetTargetProperty;
    procedure SetTargetPropertyName(const Value: string);
  public
    class constructor Create;
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    procedure UpdateTarget(IgnoreBindingMode: Boolean = True); virtual; abstract;
    function Validate: Boolean; virtual; abstract;

    procedure BeginEdit; virtual; abstract;
    procedure CancelEdit; virtual; abstract;
    procedure CommitEdit; virtual; abstract;

    property Active: Boolean read FActive write SetActive;
    property BindingGroup: TBindingGroup read FBindingGroup write SetBindingGroup;
    property Converter: IValueConverter read FConverter write SetConverter;
    property OnPropertyChanged: IEvent<TPropertyChangedEvent>
      read GetOnPropertyChanged;
    property OnValidation: IEvent<TValidationEvent> read GetOnValidation;
    property TargetProperty: IMemberExpression read FTargetProperty;
    property Updating: Boolean read GetUpdating;
    property ValidationErrors: IList<IValidationResult> read GetValidationErrors;
    property ValidationRules: IList<IValidationRule> read GetValidationRules;
  published
    property BindingMode: TBindingMode read FBindingMode write SetBindingMode
      default BindingModeDefault;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Managed: Boolean read FManaged write FManaged default True;
    property NotifyOnTargetUpdated: Boolean read FNotifyOnTargetUpdated
      write FNotifyOnTargetUpdated default False;
    property OnTargetUpdated: TPropertyChangedEvent read FOnTargetUpdated
      write FOnTargetUpdated;
    property PreventFocusChange: Boolean
      read FPreventFocusChange write FPreventFocusChange default False;
    property Target: TObject read FTarget write SetTarget;
    property TargetPropertyName: string read FTargetPropertyName
      write SetTargetPropertyName;
    property TargetUpdateTrigger: TUpdateTrigger read FTargetUpdateTrigger
      write FTargetUpdateTrigger default UpdateTriggerDefault;
    property ValidatesOnDataErrors: Boolean
      read FValidatesOnDataErrors write FValidatesOnDataErrors default False;
  end;

  TBinding = class(TBindingBase)
  protected
    FNotifyOnSourceUpdated: Boolean;
    FOnSourceUpdated: TPropertyChangedEvent;
    FSource: TObject;
    FSourceCollectionChanged: INotifyCollectionChanged;
    FSourceProperty: IMemberExpression;
    FSourcePropertyName: string;
    FSourceUpdateTrigger: TUpdateTrigger;
    FUpdateSourceExpression: TCompiledExpression;
    FUpdateTargetExpression: TCompiledExpression;
    procedure CompileExpressions; override;
    procedure DoSourceCollectionChanged(Sender: TObject; const Item: TObject;
      Action: TCollectionChangedAction);
    procedure DoSourcePropertyChanged(ASender: TObject;
      APropertyName: string; AUpdateTrigger: TUpdateTrigger);
    procedure DoSourceUpdated(ASender: TObject; APropertyName: string;
      AUpdateTrigger: TUpdateTrigger);
    procedure DoTargetPropertyChanged(ASender: TObject;
      APropertyName: string; AUpdateTrigger: TUpdateTrigger); override;
    function GetDisplayName: string; override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure RaiseValidationError;
    procedure SetBindingMode(const Value: TBindingMode); override;
    procedure SetSource(const Value: TObject);
    procedure SetSourceProperty;
    procedure SetSourcePropertyName(const Value: string);
    function ValidateCommitted: Boolean;
  public
    constructor Create(ASource: TObject = nil; ASourcePropertyName: string = '';
      ATarget: TObject = nil; ATargetPropertyName: string = '';
      ABindingMode: TBindingMode = BindingModeDefault;
      AConverter: IValueConverter = nil); reintroduce; overload;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    procedure UpdateSource(IgnoreBindingMode: Boolean = True);
    procedure UpdateTarget(IgnoreBindingMode: Boolean = True); override;
    function Validate: Boolean; override;

    procedure BeginEdit; override;
    procedure CancelEdit; override;
    procedure CommitEdit; override;

    property SourceProperty: IMemberExpression read FSourceProperty;
  published
    property NotifyOnSourceUpdated: Boolean read FNotifyOnSourceUpdated
      write FNotifyOnSourceUpdated default False;
    property OnSourceUpdated: TPropertyChangedEvent read FOnSourceUpdated
      write FOnSourceUpdated;
    property Source: TObject read FSource write SetSource;
    property SourcePropertyName: string read FSourcePropertyName
      write SetSourcePropertyName;
    property SourceUpdateTrigger: TUpdateTrigger read FSourceUpdateTrigger
      write FSourceUpdateTrigger default UpdateTriggerDefault;
  end;

  IBindable = interface
    function GetBinding: TBinding;
    property Binding: TBinding read GetBinding;
  end;

  TBindingCollection = class(TOwnedCollection<TBinding>)
  end;

  TBindingGroup = class(TComponent, INotifyPropertyChanged, IValidatable)
  private
    FBindings: TBindingCollection;
    FEditing: Boolean;
    FItems: IList<TObject>;
    FOnPropertyChanged: Event<TPropertyChangedEvent>;
    FValidationErrors: IList<IValidationResult>;
    FValidationRules: IList<IValidationRule>;
    function GetOnPropertyChanged: IEvent<TPropertyChangedEvent>;
    procedure SetBindings(const Value: TBindingCollection);
    procedure SetEditing(const Value: Boolean);
    function GetItems: IList<TObject>;
    function GetValidationErrors: IList<IValidationResult>;
    function GetValidationRules: IList<IValidationRule>;
  protected
    procedure DoPropertyChanged(const APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged);
    procedure DoValidationErrorsChanged(Sender: TObject;
      const Item: IValidationResult; Action: TCollectionChangedAction);
    procedure DoValidationRulesChanged(Sender: TObject;
      const Item: IValidationRule; Action: TCollectionChangedAction);
    procedure DefineProperties(Filer: TFiler); override;
    procedure Loaded; override;
    procedure ReadBindings(AReader: TReader);
    procedure WriteBindings(AWriter: TWriter);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AddBinding(ASource: TObject = nil; ASourcePropertyName: string = '';
      ATarget: TObject = nil; ATargetPropertyName: string = '';
      ABindingMode: TBindingMode = BindingModeDefault;
      AConverter: IValueConverter = nil): TBinding;
    procedure Bind(ASource: TObject; ATarget: TObject = nil);

    function GetBindingForTarget(ATarget: TObject): TBinding;

    procedure BeginEdit;
    procedure CancelEdit;
    procedure CommitEdit;

    procedure NotifyPropertyChanged(ASender: TObject; APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged);
    function TryGetValue(AItem: TObject; APropertyName: string;
      out AValue: TValue): Boolean;
    procedure UpdateSources(IgnoreBindingMode: Boolean = True);
    procedure UpdateTargets(IgnoreBindingMode: Boolean = True);
    function Validate: Boolean;

    property Bindings: TBindingCollection read FBindings write SetBindings;
    property Editing: Boolean read FEditing;
    property Items: IList<TObject> read GetItems;
    property OnPropertyChanged: IEvent<TPropertyChangedEvent>
      read GetOnPropertyChanged;
    property ValidationErrors: IList<IValidationResult> read GetValidationErrors;
    property ValidationRules: IList<IValidationRule> read GetValidationRules;
  end;

  EBindingException = class(Exception);

function FindBindingGroup(AComponent: TPersistent): TBindingGroup;
function GetBindingForComponent(AComponent: TPersistent): TBinding;
procedure NotifyPropertyChanged(ASender: TObject; const APropertyName: string;
  AUpdateTrigger: TUpdateTrigger = utPropertyChanged); overload;

implementation

uses
  DSharp.Bindings.Exceptions,
  DSharp.Bindings.Validations,
  DSharp.Core.Reflection,
  DSharp.Core.Utils,
  StrUtils,
  TypInfo;

var
  BindingGroups: TList;

function FindBindingGroup(AComponent: TPersistent): TBindingGroup;
var
  i: Integer;
  LOwner: TPersistent;
  LType: TRttiType;
begin
  Result := nil;
  if AComponent is TCollectionItem then
  begin
    LOwner := GetUltimateOwner(TCollectionItem(AComponent));
  end
  else
  if AComponent is TCollection then
  begin
    LOwner := GetUltimateOwner(TCollection(AComponent));
  end
  else
  if TryGetRttiType(AComponent.ClassInfo, LType) and (LType.IsInheritedFrom('TForm')
    or LType.IsInheritedFrom('TFrame') or LType.IsInheritedFrom('TDataModule')) then
  begin
    LOwner := AComponent;
  end
  else
  begin
    LOwner := GetUltimateOwner(AComponent);
  end;
  if Assigned(LOwner) and (LOwner is TComponent) then
  begin
    for i := 0 to Pred(TComponent(LOwner).ComponentCount) do
    begin
      if TComponent(LOwner).Components[i] is TBindingGroup then
      begin
        Result := TBindingGroup(TComponent(LOwner).Components[i]);
        Break;
      end;
    end;
  end
end;

function GetBindingForComponent(AComponent: TPersistent): TBinding;
var
  LBindingGroup: TBindingGroup;
begin
  Result := nil;
  LBindingGroup := FindBindingGroup(AComponent);
  if Assigned(LBindingGroup) then
  begin
    Result := LBindingGroup.GetBindingForTarget(AComponent);
  end;
end;

function IsRootProperty(const Name: string; Expression: IParameterExpression): Boolean;
var
  LRoot: string;
begin
  LRoot := Expression.Name;
  if ContainsText(LRoot, '.') then
  begin
    LRoot := LeftStr(LRoot, Pred(Pos('.', LRoot)));
  end;
  if ContainsText(LRoot, '[') then
  begin
    LRoot := LeftStr(LRoot, Pred(Pos('[', LRoot)));
  end;
  Result := SameText(Name, LRoot);
end;

procedure NotifyPropertyChanged(ASender: TObject; const APropertyName: string;
  AUpdateTrigger: TUpdateTrigger = utPropertyChanged);
var
  i: Integer;
begin
  for i := 0 to Pred(BindingGroups.Count) do
  begin
    TBindingGroup(BindingGroups[i]).NotifyPropertyChanged(
      ASender, APropertyName, AUpdateTrigger);
  end;
end;

{ BindingAttribute }

constructor BindingAttribute.Create(const ASourcePropertyName,
  ATargetPropertyName: string; ABindingMode: TBindingMode);
begin
  FBindingMode := ABindingMode;
  FSourcePropertyName := ASourcePropertyName;
  FTargetPropertyName := ATargetPropertyName;
end;

{ TBindingBase }

procedure TBindingBase.Assign(Source: TPersistent);
begin
  if Assigned(Source) and (Source is TBindingBase) then
  begin
    Active := TBindingBase(Source).Active;
//    BindingGroup := TBindingBase(Source).BindingGroup;
    Converter := TBindingBase(Source).Converter;
    Enabled := TBindingBase(Source).Enabled;
    Target := TBindingBase(Source).Target;
    TargetPropertyName := TBindingBase(Source).TargetPropertyName;
    TargetUpdateTrigger := TBindingBase(Source).TargetUpdateTrigger;
  end;
end;

procedure TBindingBase.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

class constructor TBindingBase.Create;
begin
  DataErrorValidationRule := TDataErrorValidationRule.Create();
end;

constructor TBindingBase.Create(Collection: TCollection);
begin
  inherited;

  FNotificationHandler := TNotificationHandler<TBindingBase>.Create(Self, Notification);
  FValidationErrors := TList<IValidationResult>.Create();
  FValidationErrors.OnCollectionChanged.Add(DoValidationErrorsChanged);
  FValidationRules := TList<IValidationRule>.Create();
  FValidationRules.OnCollectionChanged.Add(DoValidationRulesChanged);

  FBindingMode := BindingModeDefault;
  FEnabled := True;

  if Assigned(Collection) then
  begin
    FBindingGroup := TBindingGroup(Collection.Owner);
    FManaged := Assigned(FBindingGroup);
    FActive := FEnabled and Assigned(FBindingGroup) 
      and not (csDesigning in FBindingGroup.ComponentState);
  end;
end;

destructor TBindingBase.Destroy;
begin
  SetBindingGroup(nil);
  SetTarget(nil);

  FNotificationHandler.Free();
  FValidationErrors.OnCollectionChanged.Remove(DoValidationErrorsChanged);
  FValidationRules.OnCollectionChanged.Remove(DoValidationRulesChanged);

  inherited;
end;

procedure TBindingBase.DoPropertyChanged(const APropertyName: string;
  AUpdateTrigger: TUpdateTrigger);
begin
  FOnPropertyChanged.Invoke(Self, APropertyName, AUpdateTrigger);
end;

procedure TBindingBase.DoTargetUpdated(ASender: TObject; APropertyName: string;
  AUpdateTrigger: TUpdateTrigger);
begin
  if FNotifyOnTargetUpdated and Assigned(FOnTargetUpdated) then
  begin
    FOnTargetUpdated(ASender, APropertyName, AUpdateTrigger);
  end;
end;

procedure TBindingBase.DoValidationErrorsChanged(Sender: TObject;
  const Item: IValidationResult; Action: TCollectionChangedAction);
begin
  DoPropertyChanged('ValidationErrors');
end;

procedure TBindingBase.DoValidationRulesChanged(Sender: TObject;
  const Item: IValidationRule; Action: TCollectionChangedAction);
begin
  Validate();
  DoPropertyChanged('ValidationRules');
end;

procedure TBindingBase.EndUpdate;
begin
  Dec(FUpdateCount);
end;

function TBindingBase.GetOnPropertyChanged: IEvent<TPropertyChangedEvent>;
begin
  Result := FOnPropertyChanged;
end;

function TBindingBase.GetOnValidation: IEvent<TValidationEvent>;
begin
  Result := FOnValidation;
end;

function TBindingBase.GetUpdating: Boolean;
begin
  Result := FUpdateCount > 0;
end;

function TBindingBase.GetValidationErrors: IList<IValidationResult>;
begin
  Result := FValidationErrors;
end;

function TBindingBase.GetValidationRules: IList<IValidationRule>;
begin
  Result := FValidationRules;
end;

procedure TBindingBase.Notification(AComponent: TComponent;
  AOperation: TOperation);
begin
  if AOperation = opRemove then
  begin
    if AComponent = FTarget then
    begin
      FTarget := nil;
      if not FManaged then
      begin
        Free;
      end;
    end;
  end;
end;

function TBindingBase.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TBindingBase.SetActive(const Value: Boolean);
begin
  if FEnabled and (FActive <> Value) then
  begin
    FActive := Value;

    if FActive then
    begin
      UpdateTarget(True);
    end;
  end;
end;

procedure TBindingBase.SetBindingGroup(const Value: TBindingGroup);
begin
  if FBindingGroup <> Value then
  begin
    FBindingGroup := Value;

    if Assigned(FBindingGroup) then
    begin
      Collection := FBindingGroup.Bindings;
    end;
  end;
end;

procedure TBindingBase.SetBindingMode(const Value: TBindingMode);
begin
  FBindingMode := Value;

  SetTargetProperty();
end;

procedure TBindingBase.SetConverter(const Value: IValueConverter);
begin
  if FConverter <> Value then
  begin
    FConverter := Value;
    CompileExpressions();
    UpdateTarget(True);
  end;
end;

procedure TBindingBase.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
  if not FEnabled and FActive then
  begin
    FActive := False;
  end;
end;

procedure TBindingBase.SetTarget(const Value: TObject);
var
  LNotifyPropertyChanged: INotifyPropertyChanged;
  LPropertyChanged: IEvent<TPropertyChangedEvent>;
begin
  if FTarget <> Value then
  begin
    if Assigned(FTarget) then
    begin
      if FTarget is TComponent then
      begin
        TComponent(FTarget).RemoveFreeNotification(FNotificationHandler);
      end;

      if Supports(FTarget, INotifyPropertyChanged, LNotifyPropertyChanged) then
      begin
        LPropertyChanged := LNotifyPropertyChanged.OnPropertyChanged;
        LPropertyChanged.Remove(DoTargetPropertyChanged);
      end;
    end;

    FTarget := Value;
    SetTargetProperty();

    if Assigned(FTarget) then
    begin
      if FTarget is TComponent then
      begin
        TComponent(FTarget).FreeNotification(FNotificationHandler);
      end;

      if Supports(FTarget, INotifyPropertyChanged, LNotifyPropertyChanged) then
      begin
        LPropertyChanged := LNotifyPropertyChanged.OnPropertyChanged;
        LPropertyChanged.Add(DoTargetPropertyChanged);
      end;
    end;

    UpdateTarget(True);
  end;
end;

procedure TBindingBase.SetTargetProperty;
begin
  FTargetProperty := Expression.PropertyAccess(
    Expression.Constant(FTarget), FTargetPropertyName);

  CompileExpressions();
end;

procedure TBindingBase.SetTargetPropertyName(const Value: string);
begin
  if not SameText(FTargetPropertyName, Value) then
  begin
    FTargetPropertyName := Value;
    if Assigned(FTarget) then
    begin
      SetTargetProperty();

      UpdateTarget(True);
    end;
  end;
end;

function TBindingBase._AddRef: Integer;
begin
  Result := -1;
end;

function TBindingBase._Release: Integer;
begin
  Result := -1;
end;

{ TBinding }

procedure TBinding.Assign(Source: TPersistent);
begin
  inherited;
  if Assigned(Source) and (Source is TBinding) then
  begin
    Self.Source := TBinding(Source).Source;
    Self.SourcePropertyName := TBinding(Source).SourcePropertyName;
    Self.SourceUpdateTrigger := TBinding(Source).SourceUpdateTrigger;
  end;
end;

procedure TBinding.BeginEdit;
var
  LEditable: IEditable;
begin
  if FActive and Assigned(FSource)
    and Supports(FSource, IEditable, LEditable) then
  begin
    LEditable.BeginEdit();
  end;
end;

procedure TBinding.CancelEdit;
var
  LEditable: IEditable;
begin
  if FActive and Assigned(FSource)
    and Supports(FSource, IEditable, LEditable) then
  begin
    LEditable.CancelEdit();
  end;
end;

procedure TBinding.CommitEdit;
var
  LEditable: IEditable;
begin
  if FActive and Assigned(FSource)
    and Supports(FSource, IEditable, LEditable) then
  begin
    LEditable.EndEdit();
  end;
end;

procedure TBinding.CompileExpressions;
begin
  if Assigned(FSourceProperty) and Assigned(FTargetProperty) then
  begin
    if Assigned(FConverter) then
    begin
      FUpdateSourceExpression :=
        Expression.Convert(
          FSourceProperty,
          FTargetProperty,
          function(const Value: TValue): TValue
          begin
            Result := FConverter.ConvertBack(Value);
          end).Compile();

      FUpdateTargetExpression :=
        Expression.Convert(
          FTargetProperty,
          FSourceProperty,
          function(const Value: TValue): TValue
          begin
            Result := FConverter.Convert(Value);
          end).Compile();
    end
    else
    begin
      FUpdateSourceExpression :=
        Expression.Convert(
          FSourceProperty,
          FTargetProperty).Compile();

      FUpdateTargetExpression :=
        Expression.Convert(
          FTargetProperty,
          FSourceProperty).Compile();
    end;
  end
  else
  begin
    FUpdateSourceExpression := Expression.Empty.Compile();
    FUpdateTargetExpression := Expression.Empty.Compile();
  end;
end;

constructor TBinding.Create(ASource: TObject; ASourcePropertyName: string;
  ATarget: TObject; ATargetPropertyName: string; ABindingMode: TBindingMode;
  AConverter: IValueConverter);
begin
  Create(nil);
  FActive := False;

  FBindingMode := ABindingMode;

  FSourcePropertyName := ASourcePropertyName;
  SetSource(ASource);
  FTargetPropertyName := ATargetPropertyName;
  SetTarget(ATarget);

  SetConverter(AConverter);
  FActive := True;

  UpdateTarget(True);
end;

destructor TBinding.Destroy;
begin
  if IsValid(FSource) then  // workaround for already freed non TComponent source
  begin
    SetSource(nil);
  end;

  inherited;
end;

procedure TBinding.DoSourceCollectionChanged(Sender: TObject;
  const Item: TObject; Action: TCollectionChangedAction);
var
  LCollectionView: ICollectionView;
  LEvent: IEvent<TCollectionChangedEvent>;
begin
  if Supports(FTarget, ICollectionView, LCollectionView) then
  begin
    LEvent := LCollectionView.OnCollectionChanged;
    LEvent.Invoke(Sender, Item, Action);
  end;
end;

procedure TBinding.DoSourcePropertyChanged(ASender: TObject;
  APropertyName: string; AUpdateTrigger: TUpdateTrigger);
begin
  if (FUpdateCount = 0) and (FBindingMode in [bmOneWay..bmTwoWay])
    and (AUpdateTrigger = FTargetUpdateTrigger)
    and IsRootProperty(APropertyName, FSourceProperty) then
  begin
    BeginUpdate();
    try
      DoTargetUpdated(ASender, APropertyName, AUpdateTrigger);

      UpdateTarget(True);
    finally
      EndUpdate();
    end;
  end;
end;

procedure TBinding.DoSourceUpdated(ASender: TObject; APropertyName: string;
  AUpdateTrigger: TUpdateTrigger);
begin
  if FNotifyOnSourceUpdated and Assigned(FOnSourceUpdated) then
  begin
    FOnSourceUpdated(ASender, APropertyName, AUpdateTrigger);
  end;
end;

procedure TBinding.DoTargetPropertyChanged(ASender: TObject;
  APropertyName: string; AUpdateTrigger: TUpdateTrigger);
begin
  if (FUpdateCount = 0) and (FBindingMode in [bmTwoWay..bmOneWayToSource])
    and (AUpdateTrigger = FSourceUpdateTrigger)
    and IsRootProperty(APropertyName, FTargetProperty) then
  begin
    BeginUpdate();
    try
      if Validate() then
      begin
        DoSourceUpdated(ASender, APropertyName, AUpdateTrigger);

        UpdateSource(True);
      end
      else
      begin
        if FPreventFocusChange then
        begin
          RaiseValidationError();
        end;
      end;
    finally
      EndUpdate();
    end;

    if not ValidateCommitted()
      and (FSourceUpdateTrigger = utLostFocus) and FPreventFocusChange then
    begin
      RaiseValidationError();
    end;
  end;
end;

function TBinding.GetDisplayName: string;
const
  BindingModeNames: array[TBindingMode] of string = ('-->', '<->', '<--', '*->');
begin
  Result := inherited;
  if Assigned(FSource) and (FSource is TComponent)
    and Assigned(FTarget) and (FTarget is TComponent)
    and not SameText(Trim(FSourcePropertyName), EmptyStr)
    and not SameText(Trim(FTargetPropertyName), EmptyStr) then
  begin
    Result := Result + Format(' (%s.%s %s %s.%s)', [
      TComponent(FSource).Name, FSourcePropertyName, BindingModeNames[FBindingMode],
      TComponent(FTarget).Name, FTargetPropertyName]);
  end
  else
  begin
    Result := Result + ' (definition uncomplete)';
  end;
end;

procedure TBinding.Notification(AComponent: TComponent; AOperation: TOperation);
begin
  inherited;

  if AOperation = opRemove then
  begin
    if AComponent = FSource then
    begin
      FSource := nil;
      if not FManaged then
      begin
        Free;
      end;
    end;
  end;
end;

procedure TBinding.RaiseValidationError;
begin
  raise EValidationError.Create(Self);
end;

procedure TBinding.SetBindingMode(const Value: TBindingMode);
begin
  inherited;

  SetSourceProperty();
end;

procedure TBinding.SetSource(const Value: TObject);
var
  LNotifyPropertyChanged: INotifyPropertyChanged;
  LPropertyChanged: IEvent<TPropertyChangedEvent>;
  LSourceCollectionChanged: IEvent<TCollectionChangedEvent>;
begin
  if FSource <> Value then
  begin
    if Assigned(FSource) then
    begin
      if FSource is TComponent then
      begin
        TComponent(FSource).RemoveFreeNotification(FNotificationHandler);
      end;

      if Supports(FSource, INotifyPropertyChanged, LNotifyPropertyChanged) then
      begin
        LPropertyChanged := LNotifyPropertyChanged.OnPropertyChanged;
        LPropertyChanged.Remove(DoSourcePropertyChanged);
      end;

      if Assigned(FSourceCollectionChanged) then
      begin
        LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
        LSourceCollectionChanged.Remove(DoSourceCollectionChanged);
      end;
    end;

    FSource := Value;
    SetSourceProperty();

    if Assigned(FSource) then
    begin
      if FSource is TComponent then
      begin
        TComponent(FSource).FreeNotification(FNotificationHandler);
      end;

      if Supports(FSource, INotifyPropertyChanged, LNotifyPropertyChanged) then
      begin
        LPropertyChanged := LNotifyPropertyChanged.OnPropertyChanged;
        LPropertyChanged.Add(DoSourcePropertyChanged);
      end;

      // maybe the source itself is a collection?
      if not Assigned(FSourceCollectionChanged)
        and Supports(FSource, INotifyCollectionChanged, FSourceCollectionChanged) then
      begin
        LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
        LSourceCollectionChanged.Add(DoSourceCollectionChanged);
      end;
    end;

    UpdateTarget(True);
  end;
end;

procedure TBinding.SetSourceProperty;
var
  LSourceCollectionChanged: IEvent<TCollectionChangedEvent>;
begin
  if Assigned(FSourceCollectionChanged) then
  begin
    LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
    LSourceCollectionChanged.Remove(DoSourceCollectionChanged);
  end;

  FSourceProperty := Expression.PropertyAccess(
    Expression.Constant(FSource), FSourcePropertyName);

  CompileExpressions();

  if Assigned(FSourceProperty) and FSourceProperty.Member.RttiType.IsInstance
    and Supports(FSourceProperty.Value.AsObject,
    INotifyCollectionChanged, FSourceCollectionChanged) then
  begin
    LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
    LSourceCollectionChanged.Add(DoSourceCollectionChanged);
  end;
end;

procedure TBinding.SetSourcePropertyName(const Value: string);
begin
  if not SameText(FSourcePropertyName, Value) then
  begin
    FSourcePropertyName := Value;
    if Assigned(FSource) then
    begin
      SetSourceProperty;

      UpdateTarget(True);
    end;
  end;
end;

procedure TBinding.UpdateSource(IgnoreBindingMode: Boolean = True);
begin
  if Assigned(Self) and FActive
    and (IgnoreBindingMode or (FBindingMode in [bmTwoWay..bmOneWayToSource]))
    and Assigned(FTarget) and Assigned(FTargetProperty)
    and Assigned(FSource) and Assigned(FSourceProperty)
    and FTargetProperty.Member.IsReadable and FSourceProperty.Member.IsWritable then
  begin
    BeginUpdate();
    try
      FUpdateSourceExpression();
      FValidationErrors.Clear();
    finally
      EndUpdate();
    end;
  end;
end;

procedure TBinding.UpdateTarget(IgnoreBindingMode: Boolean = True);
var
  LSourceCollectionChanged: IEvent<TCollectionChangedEvent>;
begin
  if Assigned(Self) and FActive
    and (IgnoreBindingMode or (FBindingMode in [bmOneWay..bmTwoWay]))
    and (not Assigned(FBindingGroup) or not (csLoading in FBindingGroup.ComponentState))
    and Assigned(FTarget) and Assigned(FTargetProperty)
    and Assigned(FSource) and Assigned(FSourceProperty)
    and FTargetProperty.Member.IsWritable and FSourceProperty.Member.IsReadable then
  begin
    BeginUpdate();
    try
      if Assigned(FSourceCollectionChanged) then
      begin
        LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
        LSourceCollectionChanged.Remove(DoSourceCollectionChanged);
      end;

      FSourceCollectionChanged := nil;

      if FSourceProperty.Member.RttiType.IsInstance
        and Supports(FSourceProperty.Value.AsObject,
        INotifyCollectionChanged, FSourceCollectionChanged) then
      begin
        LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
        LSourceCollectionChanged.Add(DoSourceCollectionChanged);
      end;

      FUpdateTargetExpression();
      FValidationErrors.Clear();
    finally
      EndUpdate();
    end;
  end;
end;

function TBinding.Validate: Boolean;
var
  LConverted: Boolean;
  LSourceValue: TValue;
  LTargetValue: TValue;
  LValidationResult: IValidationResult;
  LValidationRule: IValidationRule;
begin
  FValidationErrors.Clear();
  Result := True;

  LValidationRule := nil;
  try
    if Assigned(FTarget) and Assigned(FTargetProperty)
      and FTargetProperty.Member.IsReadable then
    begin
      LTargetValue := FTargetProperty.Value;

      for LValidationRule in FValidationRules do
      begin
        if LValidationRule.ValidationStep = vsRawProposedValue then
        begin
          LValidationResult := LValidationRule.Validate(LTargetValue);
          if Assigned(LValidationResult) then
          begin
            FOnValidation.Invoke(Self, LValidationRule, LValidationResult);
            if not LValidationResult.IsValid then
            begin
              FValidationErrors.Add(LValidationResult);
              Result := False;
              Break;
            end;
          end;
        end;
      end;

      if Result then
      begin
        LConverted := False;

        for LValidationRule in FValidationRules do
        begin
          if LValidationRule.ValidationStep = vsConvertedProposedValue then
          begin
            if not LConverted then
            begin
              if Assigned(FConverter) then
              begin
                LSourceValue := FConverter.ConvertBack(LTargetValue);
              end
              else
              begin
                LSourceValue := LTargetValue;
              end;

              LConverted := True;
            end;

            LValidationResult := LValidationRule.Validate(LSourceValue);
            FOnValidation.Invoke(Self, LValidationRule, LValidationResult);
            if not LValidationResult.IsValid then
            begin
              FValidationErrors.Add(LValidationResult);
              Result := False;
              Break;
            end;
          end;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      FOnValidation.Invoke(Self, LValidationRule, TValidationResult.Create(False, E.Message));
      Result := False;
    end;
  end;
end;

function TBinding.ValidateCommitted: Boolean;
var
  LValidationResult: IValidationResult;
begin
  Result := True;

  if FValidatesOnDataErrors then
  begin
    LValidationResult := TBindingBase.DataErrorValidationRule.Validate(TValue.From<TBinding>(Self));
    if not LValidationResult.IsValid then
    begin
      FValidationErrors.Add(LValidationResult);
      Result := False;
    end;
  end;
end;

{ TBindingGroup }

function TBindingGroup.AddBinding(ASource: TObject; ASourcePropertyName: string;
  ATarget: TObject; ATargetPropertyName: string; ABindingMode: TBindingMode;
  AConverter: IValueConverter): TBinding;
begin
  Result := Bindings.Add();
  Result.Source := ASource;
  Result.SourcePropertyName := ASourcePropertyName;
  Result.Target := ATarget;
  Result.TargetPropertyName := ATargetPropertyName;
  Result.BindingMode := ABindingMode;
  Result.Converter := AConverter;
end;

procedure TBindingGroup.BeginEdit;
var
  LBinding: TBinding;
begin
  if not FEditing then
  begin
    for LBinding in FBindings do
    begin
      LBinding.BeginEdit();
    end;

    SetEditing(True);
  end;
end;

procedure TBindingGroup.Bind(ASource, ATarget: TObject);
var
  LField: TRttiField;
  LBindingAttribute: BindingAttribute;
  LTarget: TObject;
begin
  if not Assigned(ASource) then
  begin
    raise EBindingException.Create('Binding source not specified');
  end;

  LTarget := ATarget;
  if not Assigned(LTarget) then
  begin
    LTarget := Owner;
    if not Assigned(LTarget) then
    begin
      raise EBindingException.Create('Binding target not specified');
    end;
  end;

  for LField in LTarget.GetFields do
  begin
    for LBindingAttribute in LField.GetAttributesOfType<BindingAttribute> do
    begin
      if LField.RttiType.IsInstance then
      begin
        AddBinding(ASource, LBindingAttribute.SourcePropertyName,
          LField.GetValue(LTarget).AsObject, LBindingAttribute.TargetPropertyName,
          LBindingAttribute.BindingMode);
      end
      else
      begin
        raise EBindingException.CreateFmt('Could not bind to %s', [LField.Name]);
      end;
    end;
  end;
end;

procedure TBindingGroup.CancelEdit;
var
  LBinding: TBinding;
begin
  if FEditing then
  begin
    for LBinding in FBindings do
    begin
      LBinding.CancelEdit();
    end;

    SetEditing(False);
  end;
end;

procedure TBindingGroup.CommitEdit;
var
  LBinding: TBinding;
begin
  if FEditing then
  begin
    for LBinding in FBindings do
    begin
      LBinding.CommitEdit();
    end;

    SetEditing(False);
  end;
end;

constructor TBindingGroup.Create(AOwner: TComponent);
var
  i: Integer;
begin
  FBindings := TBindingCollection.Create(Self);
  FItems := TList<TObject>.Create();
  FValidationErrors := TList<IValidationResult>.Create();
  FValidationErrors.OnCollectionChanged.Add(DoValidationErrorsChanged);
  FValidationRules := TList<IValidationRule>.Create();
  FValidationRules.OnCollectionChanged.Add(DoValidationRulesChanged);

  if Assigned(AOwner) then
  begin
    for i := 0 to AOwner.ComponentCount - 1 do
    begin
      if AOwner.Components[i] is TBindingGroup then
      begin
        raise EBindingException.Create('Only one binding group allowed');
      end;
    end;
  end;
  inherited;
  BindingGroups.Add(Self);
end;

destructor TBindingGroup.Destroy;
begin
  BindingGroups.Remove(Self);
  FBindings.Free();
  FValidationErrors.OnCollectionChanged.Remove(DoValidationErrorsChanged);
  FValidationRules.OnCollectionChanged.Remove(DoValidationRulesChanged);
  inherited;
end;

procedure TBindingGroup.DoPropertyChanged(const APropertyName: string;
  AUpdateTrigger: TUpdateTrigger);
begin
  FOnPropertyChanged.Invoke(Self, APropertyName, AUpdateTrigger);
end;

procedure TBindingGroup.DoValidationErrorsChanged(Sender: TObject;
  const Item: IValidationResult; Action: TCollectionChangedAction);
begin
  DoPropertyChanged('ValidationErrors');
end;

procedure TBindingGroup.DoValidationRulesChanged(Sender: TObject;
  const Item: IValidationRule; Action: TCollectionChangedAction);
begin
  Validate();
  DoPropertyChanged('ValidationRules');
end;

function TBindingGroup.GetBindingForTarget(ATarget: TObject): TBinding;
var
  LBinding: TBinding;
begin
  Result := nil;
  for LBinding in Bindings do
  begin
    if LBinding.Target = ATarget then
    begin
      Result := LBinding;
      Break;
    end;
  end;
  if not Assigned(Result) then
  begin
    Result := Bindings.Add;
    Result.Active := False;
    Result.Target := ATarget;
  end;
end;

function TBindingGroup.GetItems: IList<TObject>;
var
  LBinding: TBinding;
begin
  // TODO: trigger this when bindings change
  FItems.Clear();

  for LBinding in FBindings do
  begin
    if Assigned(LBinding.Source) and not FItems.Contains(LBinding.Source) then
    begin
      FItems.Add(LBinding.Source);
    end;
  end;

  Result := FItems;
end;

function TBindingGroup.GetOnPropertyChanged: IEvent<TPropertyChangedEvent>;
begin
  Result := FOnPropertyChanged;
end;

function TBindingGroup.GetValidationErrors: IList<IValidationResult>;
begin
  Result := FValidationErrors;
end;

function TBindingGroup.GetValidationRules: IList<IValidationRule>;
begin
  Result := FValidationRules;
end;

procedure TBindingGroup.Loaded;
var
  LBinding: TBinding;
begin
  inherited;

  for LBinding in FBindings do
  begin
    if LBinding.Active then
    begin
      LBinding.UpdateTarget(True);
    end;
  end;
end;

procedure TBindingGroup.NotifyPropertyChanged(ASender: TObject;
  APropertyName: string; AUpdateTrigger: TUpdateTrigger);
var
  LBinding: TBinding;
begin
  if Assigned(Self) then
  begin
    for LBinding in FBindings do
    begin
      if LBinding.Source = ASender then
      begin
        LBinding.DoSourcePropertyChanged(ASender, APropertyName, AUpdateTrigger);
      end;
      if LBinding.Target = ASender then
      begin
        LBinding.DoTargetPropertyChanged(ASender, APropertyName, AUpdateTrigger);
      end;
    end;
  end;
end;

procedure TBindingGroup.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('Bindings', ReadBindings, WriteBindings, True);
end;

procedure TBindingGroup.ReadBindings(AReader: TReader);
begin
  AReader.ReadValue();
  AReader.ReadCollection(FBindings);
end;

procedure TBindingGroup.SetBindings(const Value: TBindingCollection);
begin
  FBindings.Assign(Value);
end;

procedure TBindingGroup.SetEditing(const Value: Boolean);
begin
  FEditing := Value;
  DoPropertyChanged('Editing');
end;

function TBindingGroup.TryGetValue(AItem: TObject; APropertyName: string;
  out AValue: TValue): Boolean;
var
  LBinding: TBinding;
begin
  Result := False;

  for LBinding in FBindings do
  begin
    if (LBinding.Source = AItem)
      and SameText(LBinding.SourcePropertyName, APropertyName) then
    begin
      AValue := LBinding.SourceProperty.Value;
      Result := True;
      Break;
    end;
  end;
end;

procedure TBindingGroup.UpdateSources(IgnoreBindingMode: Boolean = True);
var
  LBinding: TBinding;
begin
  if Validate() then
  begin
    for LBinding in FBindings do
    begin
      LBinding.UpdateSource(IgnoreBindingMode);
    end;
  end;
end;

procedure TBindingGroup.UpdateTargets(IgnoreBindingMode: Boolean = True);
var
  LBinding: TBinding;
begin
  for LBinding in FBindings do
  begin
    LBinding.UpdateTarget(IgnoreBindingMode);
  end;
end;

function TBindingGroup.Validate: Boolean;
var
  LBinding: TBinding;
  LValidationResult: IValidationResult;
  LValidationRule: IValidationRule;
begin
  FValidationErrors.Clear();
  Result := True;

  for LValidationRule in FValidationRules do
  begin
    if LValidationRule.ValidationStep in [vsRawProposedValue, vsConvertedProposedValue] then
    begin
      LValidationResult := LValidationRule.Validate(Self);
      if not LValidationResult.IsValid then
      begin
        FValidationErrors.Add(LValidationResult);
        Result := False;
      end;
    end;
  end;

  for LBinding in FBindings do
  begin
    Result := Result and LBinding.Validate();

    FValidationErrors.AddRange(LBinding.ValidationErrors.ToArray);
  end;
end;

procedure TBindingGroup.WriteBindings(AWriter: TWriter);
var
  i: Integer;
begin
  for i := Pred(FBindings.Count) downto 0 do
  begin
    if not Assigned(FBindings[i].Source) or not Assigned(FBindings[i].Target)
      or (Trim(FBindings[i].SourcePropertyName) = '')
      or (Trim(FBindings[i].TargetPropertyName) = '') then
    begin
      FBindings.Delete(i);
    end;
  end;
  AWriter.WriteCollection(FBindings);
end;

initialization
  BindingGroups := TList.Create();

finalization
  BindingGroups.Free();

end.
