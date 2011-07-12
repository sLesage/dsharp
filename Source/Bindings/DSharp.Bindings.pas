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
  DSharp.Collections,
  DSharp.Core.Collections,
  DSharp.Core.DataConversion,
  DSharp.Core.Events,
  DSharp.Core.NotificationHandler,
  DSharp.Core.PropertyPath,
  DSharp.Core.Validations,
  Rtti,
  SysUtils;

type
  TBindingMode = (bmOneWay, bmTwoWay, bmOneWayToSource);
  TUpdateTrigger = (utPropertyChanged, utLostFocus, utExplicit);

const
  BindingModeDefault = bmTwoWay;
  UpdateTriggerDefault = utPropertyChanged;

type
  TPropertyChangedEvent = procedure(ASender: TObject;
    APropertyName: string; AUpdateTrigger: TUpdateTrigger = utPropertyChanged) of object;

  INotifyPropertyChanged = interface
    ['{6627279B-8112-4A92-BBD3-795185A41966}']
    function GetOnPropertyChanged: TEvent<TPropertyChangedEvent>;
    property OnPropertyChanged: TEvent<TPropertyChangedEvent>
      read GetOnPropertyChanged;
  end;

  TBindingGroup = class;

  TBindingBase = class abstract(TCollectionItem,
    INotifyPropertyChanged, IValidatable)
  private
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  protected
    FActive: Boolean;
    FBindingGroup: TBindingGroup;
    FBindingMode: TBindingMode;
    FConverter: IValueConverter;
    FNotificationHandler: TNotificationHandler<TBindingBase>;
    FNotifyOnTargetUpdated: Boolean;
    FOnPropertyChanged: TEvent<TPropertyChangedEvent>;
    FOnTargetUpdated: TPropertyChangedEvent;
    FOnValidation: TEvent<TValidationEvent>;
    FTarget: TObject;
    FTargetProperty: IPropertyPath;
    FTargetPropertyName: string;
    FTargetUpdateTrigger: TUpdateTrigger;
    FUpdateCount: Integer;
    FValidationErrors: TList<IValidationResult>;
    FValidationRules: TList<IValidationRule>;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure DoPropertyChanged(const APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged);
    procedure DoTargetPropertyChanged(ASender: TObject;
      APropertyName: string; AUpdateTrigger: TUpdateTrigger); virtual; abstract;
    procedure DoTargetUpdated(ASender: TObject; APropertyName: string;
      AUpdateTrigger: TUpdateTrigger);
    procedure DoValidationErrorsChanged(Sender: TObject;
      Item: IValidationResult; Action: TCollectionChangedAction);
    procedure DoValidationRulesChanged(Sender: TObject;
      Item: IValidationRule; Action: TCollectionChangedAction);
    function GetOnPropertyChanged: TEvent<TPropertyChangedEvent>;
    function GetOnValidation: TEvent<TValidationEvent>;
    function GetValidationErrors: TList<IValidationResult>;
    function GetValidationRules: TList<IValidationRule>;
    procedure InitConverter; virtual; abstract;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); virtual;
    procedure SetActive(const Value: Boolean);
    procedure SetBindingGroup(const Value: TBindingGroup);
    procedure SetConverter(const Value: IValueConverter);
    procedure SetTarget(const Value: TObject);
    procedure SetTargetPropertyName(const AValue: string);
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    procedure UpdateTarget; virtual; abstract;
    function Validate: Boolean; virtual; abstract;

    procedure BeginEdit; virtual; abstract;
    procedure CancelEdit; virtual; abstract;
    procedure CommitEdit; virtual; abstract;

    property Active: Boolean read FActive write SetActive;
    property BindingGroup: TBindingGroup read FBindingGroup write SetBindingGroup;
    property Converter: IValueConverter read FConverter write SetConverter;
    property OnPropertyChanged: TEvent<TPropertyChangedEvent>
      read GetOnPropertyChanged;
    property OnValidation: TEvent<TValidationEvent> read GetOnValidation;
    property TargetProperty: IPropertyPath read FTargetProperty;
    property ValidationErrors: TList<IValidationResult> read GetValidationErrors;
    property ValidationRules: TList<IValidationRule> read GetValidationRules;
  published
    property BindingMode: TBindingMode read FBindingMode write FBindingMode
      default BindingModeDefault;
    property NotifyOnTargetUpdated: Boolean read FNotifyOnTargetUpdated
      write FNotifyOnTargetUpdated default False;
    property OnTargetUpdated: TPropertyChangedEvent read FOnTargetUpdated
      write FOnTargetUpdated;
    property Target: TObject read FTarget write SetTarget;
    property TargetPropertyName: string read FTargetPropertyName
      write SetTargetPropertyName;
    property TargetUpdateTrigger: TUpdateTrigger read FTargetUpdateTrigger
      write FTargetUpdateTrigger default UpdateTriggerDefault;
  end;

  TBinding = class(TBindingBase)
  protected
    FNotifyOnSourceUpdated: Boolean;
    FOnSourceUpdated: TPropertyChangedEvent;
    FSource: TObject;
    FSourceCollectionChanged: INotifyCollectionChanged;
    FSourceProperty: IPropertyPath;
    FSourcePropertyName: string;
    FSourceUpdateTrigger: TUpdateTrigger;
    procedure DoSourceCollectionChanged(Sender: TObject; Item: TObject;
      Action: TCollectionChangedAction);
    procedure DoSourcePropertyChanged(ASender: TObject;
      APropertyName: string; AUpdateTrigger: TUpdateTrigger);
    procedure DoSourceUpdated(ASender: TObject; APropertyName: string;
      AUpdateTrigger: TUpdateTrigger);
    procedure DoTargetPropertyChanged(ASender: TObject;
      APropertyName: string; AUpdateTrigger: TUpdateTrigger); override;
    function GetDisplayName: string; override;
    procedure InitConverter; override;
    procedure Notification(AComponent: TComponent; AOperation: TOperation); override;
    procedure SetSource(const Value: TObject);
    procedure SetSourceProperty(AObject: TObject; APropertyName: string);
    procedure SetSourcePropertyName(const Value: string);
  public
    constructor Create(ASource: TObject = nil; ASourcePropertyName: string = '';
      ATarget: TObject = nil; ATargetPropertyName: string = '';
      ABindingMode: TBindingMode = BindingModeDefault;
      AConverter: IValueConverter = nil); reintroduce; overload;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    procedure UpdateSource;
    procedure UpdateTarget; override;
    function Validate: Boolean; override;

    procedure BeginEdit; override;
    procedure CancelEdit; override;
    procedure CommitEdit; override;

    property SourceProperty: IPropertyPath read FSourceProperty;
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

  IEditable = interface
  ['{070C6A4B-854D-49C3-910E-31963010D68F}']
    procedure BeginEdit;
    procedure CancelEdit;
    procedure EndEdit;
  end;

  TBindingCollection = class(TOwnedCollection<TBinding>)
  end;

  TBindingGroup = class(TComponent, INotifyPropertyChanged, IValidatable)
  private
    FBindings: TBindingCollection;
    FEditing: Boolean;
    FItems: TList<TObject>;
    FOnPropertyChanged: TEvent<TPropertyChangedEvent>;
    FValidationErrors: TList<IValidationResult>;
    FValidationRules: TList<IValidationRule>;
    function GetOnPropertyChanged: TEvent<TPropertyChangedEvent>;
    procedure SetBindings(const Value: TBindingCollection);
    procedure SetEditing(const Value: Boolean);
    function GetItems: TList<TObject>;
    function GetValidationErrors: TList<IValidationResult>;
    function GetValidationRules: TList<IValidationRule>;
  protected
    procedure DoPropertyChanged(const APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged);
    procedure DoValidationErrorsChanged(Sender: TObject;
      Item: IValidationResult; Action: TCollectionChangedAction);
    procedure DoValidationRulesChanged(Sender: TObject;
      Item: IValidationRule; Action: TCollectionChangedAction);
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadBindings(AReader: TReader);
    procedure WriteBindings(AWriter: TWriter);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetBindingForTarget(ATarget: TObject): TBinding;

    procedure BeginEdit;
    procedure CancelEdit;
    procedure CommitEdit;

    function TryGetValue(AItem: TObject; APropertyName: string;
      out AValue: TValue): Boolean;
    procedure UpdateSources;
    procedure UpdateTargets;
    function Validate: Boolean;

    property Editing: Boolean read FEditing;

    property Items: TList<TObject> read GetItems;
    property OnPropertyChanged: TEvent<TPropertyChangedEvent>
      read GetOnPropertyChanged;
    property ValidationErrors: TList<IValidationResult> read GetValidationErrors;
    property ValidationRules: TList<IValidationRule> read GetValidationRules;
  published
    property Bindings: TBindingCollection read FBindings write SetBindings;
  end;

function FindBindingGroup(AComponent: TPersistent): TBindingGroup;
function GetBindingForComponent(AComponent: TComponent): TBinding;

implementation

uses
  DSharp.Core.DataConversion.Default,
  Forms;

function FindBindingGroup(AComponent: TPersistent): TBindingGroup;
var
  i: Integer;
  LOwner: TPersistent;
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
  if (AComponent is TForm) or (AComponent is TFrame) or (AComponent is TDataModule) then
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

function GetBindingForComponent(AComponent: TComponent): TBinding;
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

{ TBindingBase }

procedure TBindingBase.Assign(Source: TPersistent);
begin
  if Assigned(Source) and (Source is TBindingBase) then
  begin
    Active := TBindingBase(Source).Active;
//    BindingGroup := TBindingBase(Source).BindingGroup;
    Converter := TBindingBase(Source).Converter;
    Target := TBindingBase(Source).Target;
    TargetPropertyName := TBindingBase(Source).TargetPropertyName;
    TargetUpdateTrigger := TBindingBase(Source).TargetUpdateTrigger;
  end;
end;

procedure TBindingBase.BeginUpdate;
begin
  Inc(FUpdateCount);
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

  FActive := Assigned(Collection) and not (csDesigning in TBindingGroup(TBindingCollection(
    Collection).Owner).ComponentState);
end;

destructor TBindingBase.Destroy;
begin
  SetBindingGroup(nil);
  SetTarget(nil);

  FNotificationHandler.Free();
  FValidationErrors.OnCollectionChanged.Remove(DoValidationErrorsChanged);
  FValidationErrors.Free();
  FValidationRules.OnCollectionChanged.Remove(DoValidationRulesChanged);
  FValidationRules.Free();

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
  if Assigned(FOnTargetUpdated) then
  begin
    FOnTargetUpdated(ASender, APropertyName, AUpdateTrigger);
  end;
end;

procedure TBindingBase.DoValidationErrorsChanged(Sender: TObject;
  Item: IValidationResult; Action: TCollectionChangedAction);
begin
  DoPropertyChanged('ValidationErrors');
end;

procedure TBindingBase.DoValidationRulesChanged(Sender: TObject;
  Item: IValidationRule; Action: TCollectionChangedAction);
begin
  Validate();
  DoPropertyChanged('ValidationRules');
end;

procedure TBindingBase.EndUpdate;
begin
  Dec(FUpdateCount);
end;

function TBindingBase.GetOnPropertyChanged: TEvent<TPropertyChangedEvent>;
begin
  Result := FOnPropertyChanged.EventHandler;
end;

function TBindingBase.GetOnValidation: TEvent<TValidationEvent>;
begin
  Result := FOnValidation.EventHandler;
end;

function TBindingBase.GetValidationErrors: TList<IValidationResult>;
begin
  Result := FValidationErrors;
end;

function TBindingBase.GetValidationRules: TList<IValidationRule>;
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
      Free;
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
  if FActive <> Value then
  begin
    FActive := Value;
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

procedure TBindingBase.SetConverter(const Value: IValueConverter);
begin
  if FConverter <> Value then
  begin
    FConverter := Value;

    UpdateTarget();
  end;
  InitConverter();
end;

procedure TBindingBase.SetTarget(const Value: TObject);
var
  LNotifyPropertyChanged: INotifyPropertyChanged;
  LPropertyChanged: TEvent<TPropertyChangedEvent>;
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
    FTargetProperty := nil;

    if Assigned(FTarget) then
    begin
      FTargetProperty := TPropertyPath.Create(FTarget, FTargetPropertyName);

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

    UpdateTarget();
  end;
end;

procedure TBindingBase.SetTargetPropertyName(const AValue: string);
begin
  if not SameText(FTargetPropertyName, AValue) then
  begin
    FTargetPropertyName := AValue;
    if Assigned(FTarget) then
    begin
      FTargetProperty := TPropertyPath.Create(FTarget, FTargetPropertyName);
      UpdateTarget();
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

constructor TBinding.Create(ASource: TObject; ASourcePropertyName: string;
  ATarget: TObject; ATargetPropertyName: string; ABindingMode: TBindingMode;
  AConverter: IValueConverter);
begin
  inherited Create(nil);
  FActive := False;

  FBindingMode := ABindingMode;

  FSourcePropertyName := ASourcePropertyName;
  SetSource(ASource);
  FTargetPropertyName := ATargetPropertyName;
  SetTarget(ATarget);

  SetConverter(AConverter);
  FActive := True;

  UpdateTarget();
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
  Item: TObject; Action: TCollectionChangedAction);
var
  LCollectionView: ICollectionView;
  LEvent: TEvent<TCollectionChangedEvent>;
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
    and (SameText(APropertyName, FSourceProperty.Root)) then
  begin
    BeginUpdate();
    try
      DoTargetUpdated(ASender, APropertyName, AUpdateTrigger);

      UpdateTarget();
    finally
      EndUpdate();
    end;
  end;
end;

procedure TBinding.DoSourceUpdated(ASender: TObject; APropertyName: string;
  AUpdateTrigger: TUpdateTrigger);
begin
  if Assigned(FOnSourceUpdated) then
  begin
    FOnSourceUpdated(ASender, APropertyName, AUpdateTrigger);
  end;
end;

procedure TBinding.DoTargetPropertyChanged(ASender: TObject;
  APropertyName: string; AUpdateTrigger: TUpdateTrigger);
begin
  if (FUpdateCount = 0) and (FBindingMode in [bmTwoWay..bmOneWayToSource])
    and (AUpdateTrigger = FSourceUpdateTrigger)
    and SameText(APropertyName, FTargetProperty.Root) then
  begin
    BeginUpdate();
    try
      if Validate() then
      begin
        DoSourceUpdated(ASender, APropertyName, AUpdateTrigger);

        UpdateSource();
      end;
    finally
      EndUpdate();
    end;
  end;
end;

function TBinding.GetDisplayName: string;
const
  BindingModeNames: array[TBindingMode] of string = ('->', '<->', '<-');
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

procedure TBinding.InitConverter;
begin
  if (not Assigned(FConverter) or ((FConverter as TObject) is TDefaultConverter))
    and Assigned(FSourceProperty) and Assigned(FSourceProperty.PropertyType)
    and Assigned(FTargetProperty) and Assigned(FTargetProperty.PropertyType) then
  begin
    FConverter := TDefaultConverter.Create(
      FSourceProperty.PropertyType.Handle,
      FTargetProperty.PropertyType.Handle);
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
      Free;
    end;
  end;
end;

procedure TBinding.SetSource(const Value: TObject);
var
  LNotifyPropertyChanged: INotifyPropertyChanged;
  LPropertyChanged: TEvent<TPropertyChangedEvent>;
  LSourceCollectionChanged: TEvent<TCollectionChangedEvent>;
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

    SetSourceProperty(Value, FSourcePropertyName);

    if Assigned(FSource) then
    begin
      SetSourceProperty(FSource, FSourcePropertyName);

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

    UpdateTarget();
  end;
end;

procedure TBinding.SetSourceProperty(AObject: TObject; APropertyName: string);
var
  LSourceCollectionChanged: TEvent<TCollectionChangedEvent>;
begin
  if Assigned(FSourceCollectionChanged) then
  begin
    LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
    LSourceCollectionChanged.Remove(DoSourceCollectionChanged);
  end;

  FSource := AObject;

  if Assigned(FSource) then
  begin
    FSourceProperty := TPropertyPath.Create(FSource, FSourcePropertyName);
  end
  else
  begin
    FSourceProperty := nil;
  end;

  if Assigned(FSource) and Assigned(FSourceProperty)
    and FSourceProperty.PropertyType.IsInstance and FSourceProperty.IsReadable
    and Supports(FSourceProperty.GetValue(FSource).AsObject,
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
      SetSourceProperty(FSource, FSourcePropertyName);

      UpdateTarget();
    end;
  end;
end;

procedure TBinding.UpdateSource;
var
  LSourceValue: TValue;
  LTargetValue: TValue;
begin
  if FActive
    and Assigned(FTarget) and Assigned(FTargetProperty)
    and Assigned(FSource) and Assigned(FSourceProperty)
    and FTargetProperty.IsReadable and FSourceProperty.IsWritable then
  begin
    BeginUpdate();
    try
      LTargetValue := FTargetProperty.GetValue(FTarget);

      InitConverter();
      LSourceValue := FConverter.ConvertBack(LTargetValue);

      FSourceProperty.SetValue(FSource, LSourceValue);
    finally
      EndUpdate();
    end;
  end;
end;

procedure TBinding.UpdateTarget;
var
  LSourceValue: TValue;
  LTargetValue: TValue;
  LSourceCollectionChanged: TEvent<TCollectionChangedEvent>;
begin
  if FActive
    and Assigned(FTarget) and Assigned(FTargetProperty)
    and Assigned(FSource) and Assigned(FSourceProperty)
    and FTargetProperty.IsWritable and FSourceProperty.IsReadable then
  begin
    LSourceValue := FSourceProperty.GetValue(FSource);

    if Assigned(FSourceCollectionChanged) then
    begin
      LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
      LSourceCollectionChanged.Remove(DoSourceCollectionChanged);
    end;

    FSourceCollectionChanged := nil;

    if LSourceValue.IsObject and Supports(LSourceValue.AsObject,
      INotifyCollectionChanged, FSourceCollectionChanged) then
    begin
      LSourceCollectionChanged := FSourceCollectionChanged.OnCollectionChanged;
      LSourceCollectionChanged.Add(DoSourceCollectionChanged);
    end;

    InitConverter();
    LTargetValue := FConverter.Convert(LSourceValue);

    FTargetProperty.SetValue(FTarget, LTargetValue);
  end;
end;

function TBinding.Validate: Boolean;
var
  LSourceValue: TValue;
  LTargetValue: TValue;
  LValidationResult: IValidationResult;
  LValidationRule: IValidationRule;
begin
  FValidationErrors.Clear();
  Result := True;

  LValidationRule := nil;
  try
    if Assigned(FTarget) and Assigned(FTargetProperty) and FTargetProperty.IsReadable then
    begin
      LTargetValue := FTargetProperty.GetValue(FTarget);

      for LValidationRule in FValidationRules do
      begin
        if LValidationRule.ValidationStep = vsRawProposedValue then
        begin
          LValidationResult := LValidationRule.Validate(LTargetValue);
          FOnValidation.Invoke(Self, LValidationRule, LValidationResult);
          if not LValidationResult.IsValid then
          begin
            FValidationErrors.Add(LValidationResult);
            Result := False;
            Break;
          end;
        end;
      end;

      if Result then
      begin
        InitConverter();
        if Assigned(FConverter) then
        begin
          LSourceValue := FConverter.ConvertBack(LTargetValue);
        end;

        for LValidationRule in FValidationRules do
        begin
          if LValidationRule.ValidationStep = vsConvertedProposedValue then
          begin
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

{ TBindingGroup }

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
  if Assigned(AOwner) then
  begin
    for i := 0 to AOwner.ComponentCount - 1 do
    begin
      if AOwner.Components[i] is TBindingGroup then
      begin
        raise Exception.Create('Only one binding group allowed');
      end;
    end;
  end;
  inherited;
  FBindings := TBindingCollection.Create(Self);
  FItems := TList<TObject>.Create();
  FValidationErrors := TList<IValidationResult>.Create();
  FValidationErrors.OnCollectionChanged.Add(DoValidationErrorsChanged);
  FValidationRules := TList<IValidationRule>.Create();
  FValidationRules.OnCollectionChanged.Add(DoValidationRulesChanged);
end;

destructor TBindingGroup.Destroy;
begin
  FBindings.Free();
  FItems.Free();
  FValidationErrors.OnCollectionChanged.Remove(DoValidationErrorsChanged);
  FValidationErrors.Free();
  FValidationRules.OnCollectionChanged.Remove(DoValidationRulesChanged);
  FValidationRules.Free();
  inherited;
end;

procedure TBindingGroup.DoPropertyChanged(const APropertyName: string;
  AUpdateTrigger: TUpdateTrigger);
begin
  FOnPropertyChanged.Invoke(Self, APropertyName, AUpdateTrigger);
end;

procedure TBindingGroup.DoValidationErrorsChanged(Sender: TObject;
  Item: IValidationResult; Action: TCollectionChangedAction);
begin
  DoPropertyChanged('ValidationErrors');
end;

procedure TBindingGroup.DoValidationRulesChanged(Sender: TObject;
  Item: IValidationRule; Action: TCollectionChangedAction);
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
      Result := LBinding as TBinding;
      Break;
    end;
  end;
  if not Assigned(Result) then
  begin
    Result := TBinding.Create(nil);
    Result.Active := False;
    Result.BindingGroup := Self;
    Result.Target := ATarget;
  end;
end;

function TBindingGroup.GetItems: TList<TObject>;
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

function TBindingGroup.GetOnPropertyChanged: TEvent<TPropertyChangedEvent>;
begin
  Result := FOnPropertyChanged.EventHandler;
end;

function TBindingGroup.GetValidationErrors: TList<IValidationResult>;
begin
  Result := FValidationErrors;
end;

function TBindingGroup.GetValidationRules: TList<IValidationRule>;
begin
  Result := FValidationRules;
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
      AValue := LBinding.SourceProperty.GetValue(AItem);
      Result := True;
      Break;
    end;
  end;
end;

procedure TBindingGroup.UpdateSources;
var
  LBinding: TBinding;
begin
  if Validate() then
  begin
    for LBinding in FBindings do
    begin
      LBinding.UpdateSource();
    end;
  end;
end;

procedure TBindingGroup.UpdateTargets;
var
  LBinding: TBinding;
begin
  for LBinding in FBindings do
  begin
    LBinding.UpdateTarget();
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
    LValidationResult := LValidationRule.Validate(Self);
    if not LValidationResult.IsValid then
    begin
      FValidationErrors.Add(LValidationResult);
      Result := False;
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

end.
