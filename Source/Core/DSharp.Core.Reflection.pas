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

unit DSharp.Core.Reflection;

interface

uses
  Rtti,
  TypInfo;

type
  TObjectHelper = class helper for TObject
  public
    function GetProperty(const AName: string): TRttiProperty;
    function GetType: TRttiType;
  end;

  TRttiPropertyHelper = class helper for TRttiProperty
  public
    function GetAttributeOfType<T: TCustomAttribute>: T;
    function GetAttributesOfType<T: TCustomAttribute>: TArray<T>;
  end;

  TRttiTypeHelper = class helper for TRttiType
  private
    function ExtractGenericArguments: string;
    function GetAsInterface: TRttiInterfaceType;
    function GetIsInterface: Boolean;
    function InheritsFrom(OtherType: PTypeInfo): Boolean;
  public
    function GetAttributeOfType<T: TCustomAttribute>: T;
    function GetAttributesOfType<T: TCustomAttribute>: TArray<T>;
    function GetGenericArguments: TArray<TRttiType>;
    function GetGenericTypeDefinition(const AIncludeUnitName: Boolean = True): string;
    function IsCovariantTo(OtherClass: TClass): Boolean; overload;
    function IsCovariantTo(OtherType: PTypeInfo): Boolean; overload;
    function IsGenericTypeDefinition: Boolean;
    function IsGenericTypeOf(const BaseTypeName: string): Boolean;
    function MakeGenericType(TypeArguments: array of PTypeInfo): TRttiType;

    property AsInterface: TRttiInterfaceType read GetAsInterface;
    property IsInterface: Boolean read GetIsInterface;
  end;

  TValueHelper = record helper for TValue
  private
    class function FromFloat(ATypeInfo: PTypeInfo; AValue: Extended): TValue; static;
  public
    function IsFloat: Boolean;
    function IsNumeric: Boolean;
    function IsString: Boolean;

    function TryCastEx(ATypeInfo: PTypeInfo; out AResult: TValue): Boolean;
  end;

function IsClassCovariantTo(ThisClass, OtherClass: TClass): Boolean;

implementation

uses
  Classes,
  StrUtils,
  SysUtils,
  Types;

var
  Context: TRttiContext;

function IsClassCovariantTo(ThisClass, OtherClass: TClass): Boolean;
var
  LType: TRttiType;
begin
  LType := Context.GetType(ThisClass);
  Result := LType.IsCovariantTo(OtherClass.ClassInfo);
end;

function MergeStrings(Values: TStringDynArray; const Delimiter: string): string;
var
  i: Integer;
begin
  for i := Low(Values) to High(Values) do
  begin
    if i = 0 then
    begin
      Result := Values[i];
    end
    else
    begin
      Result := Result + Delimiter + Values[i];
    end;
  end;
end;

{$IFDEF VER210}
function SplitString(const S: string; const Delimiter: Char): TStringDynArray;
var
  list: TStrings;
  i: Integer;
begin
  list := TStringList.Create();
  try
    list.StrictDelimiter := True;
    list.Delimiter := Delimiter;
    list.DelimitedText := s;
    SetLength(Result, list.Count);
    for i := Low(Result) to High(Result) do
    begin
      Result[i] := list[i];
    end;
  finally
    list.Free();
  end;
end;
{$ENDIF}

{ TObjectHelper }

function TObjectHelper.GetProperty(const AName: string): TRttiProperty;
var
  LType: TRttiType;
begin
  Result := nil;
  if Assigned(Self) then
  begin
    LType := GetType;
    if Assigned(LType) then
    begin
      Result := LType.GetProperty(AName);
    end;
  end;
end;

function TObjectHelper.GetType: TRttiType;
begin
  Result := nil;
  if Assigned(Self) then
  begin
    Result := Context.GetType(ClassInfo);
  end;
end;

{ TRttiTypeHelper }

function TRttiTypeHelper.ExtractGenericArguments: string;
var
  i: Integer;
begin
  i := Pos('<', Name);
  if i > 0 then
  begin
    Result := Copy(Name, Succ(i), Length(Name) - Succ(i));
  end
  else
  begin
    Result := ''
  end;
end;

function TRttiTypeHelper.GetAsInterface: TRttiInterfaceType;
begin
  Result := Self as TRttiInterfaceType;
end;

function TRttiTypeHelper.GetAttributeOfType<T>: T;
var
  LAttribute: TCustomAttribute;
begin
  Result := nil;
  for LAttribute in GetAttributes do
  begin
    if LAttribute.InheritsFrom(T) then
    begin
      Result := T(LAttribute);
      Break;
    end;
  end;end;

function TRttiTypeHelper.GetAttributesOfType<T>: TArray<T>;
var
  LAttribute: TCustomAttribute;
begin
  SetLength(Result, 0);
  for LAttribute in GetAttributes do
  begin
    if LAttribute.InheritsFrom(T) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := T(LAttribute);
    end;
  end;
end;

function TRttiTypeHelper.GetGenericArguments: TArray<TRttiType>;
var
  i: Integer;
  args: TStringDynArray;
begin
  args := SplitString(ExtractGenericArguments, ',');
  SetLength(Result, Length(args));
  for i := 0 to Pred(Length(args)) do
  begin
    Result[i] := Context.FindType(args[i]);
  end;
end;

function TRttiTypeHelper.GetGenericTypeDefinition(
  const AIncludeUnitName: Boolean = True): string;
var
  i: Integer;
  args: TStringDynArray;
begin
  args := SplitString(ExtractGenericArguments, ',');
  for i := Low(args) to High(args) do
  begin
    // naive implementation - but will work in most cases
    if (i = 0) and (Length(args) = 1) then
    begin
      args[i] := 'T';
    end
    else
    begin
      args[i] := 'T' + IntToStr(Succ(i));
    end;
  end;
  if IsPublicType and AIncludeUnitName then
  begin
    Result := Copy(QualifiedName, 1, Pos('<', QualifiedName)) + MergeStrings(args, ',') + '>';
  end
  else
  begin
    Result := Copy(Name, 1, Pos('<', Name)) + MergeStrings(args, ',') + '>';
  end;
end;

function TRttiTypeHelper.GetIsInterface: Boolean;
begin
  Result := Self is TRttiInterfaceType;
end;

function TRttiTypeHelper.InheritsFrom(OtherType: PTypeInfo): Boolean;
var
  LType: TRttiType;
begin
  Result := Handle = OtherType;

  if not Result then
  begin
    LType := BaseType;
    while Assigned(LType) and not Result do
    begin
      Result := LType.Handle = OtherType;
      LType := LType.BaseType;
    end;
  end;
end;

function TRttiTypeHelper.IsCovariantTo(OtherType: PTypeInfo): Boolean;
var
  t: TRttiType;
  args, otherArgs: TArray<TRttiType>;
  i: Integer;
begin
  Result := False;
  t := Context.GetType(OtherType);
  if Assigned(t) and IsGenericTypeDefinition then
  begin
    if SameText(GetGenericTypeDefinition, t.GetGenericTypeDefinition)
      or SameText(GetGenericTypeDefinition(False), t.GetGenericTypeDefinition(False)) then
    begin
      Result := True;
      args := GetGenericArguments;
      otherArgs := t.GetGenericArguments;
      for i := Low(args) to High(args) do
      begin
        if args[i].IsInterface and args[i].IsInterface
          and args[i].InheritsFrom(otherArgs[i].Handle) then
        begin
          Continue;
        end;

        if args[i].IsInstance and otherArgs[i].IsInstance
          and args[i].InheritsFrom(otherArgs[i].Handle) then
        begin
          Continue;
        end;

        Result := False;
        Break;
      end;
    end
    else
    begin
      if Assigned(BaseType) then
      begin
        Result := BaseType.IsCovariantTo(OtherType);
      end;
    end;
  end
  else
  begin
    Result := InheritsFrom(OtherType);
  end;
end;

function TRttiTypeHelper.IsCovariantTo(OtherClass: TClass): Boolean;
begin
  Result := Assigned(OtherClass) and IsCovariantTo(OtherClass.ClassInfo);
end;

function TRttiTypeHelper.IsGenericTypeDefinition: Boolean;
begin
  Result := Length(GetGenericArguments) > 0;
end;

function TRttiTypeHelper.IsGenericTypeOf(const BaseTypeName: string): Boolean;
begin
  Result := (Copy(Name, 1, Succ(Length(BaseTypeName))) = (BaseTypeName + '<'))
    and (Copy(Name, Length(Name), 1) = '>');
end;

function TRttiTypeHelper.MakeGenericType(TypeArguments: array of PTypeInfo): TRttiType;
var
  i: Integer;
  args: TStringDynArray;
  s: string;
begin
  if IsPublicType then
  begin
    args := SplitString(ExtractGenericArguments, ',');
    for i := Low(args) to High(args) do
    begin
      args[i] := Context.GetType(TypeArguments[i]).QualifiedName;
    end;
    s := Copy(QualifiedName, 1, Pos('<', QualifiedName)) + MergeStrings(args, ',') + '>';
    Result := Context.FindType(s);
  end
  else
  begin
    Result := nil;
  end;
end;

{ TValueHelper }

class function TValueHelper.FromFloat(ATypeInfo: PTypeInfo;
  AValue: Extended): TValue;
begin
  case GetTypeData(ATypeInfo).FloatType of
    ftSingle: Result := TValue.From<Single>(AValue);
    ftDouble: Result := TValue.From<Double>(AValue);
    ftExtended: Result := TValue.From<Extended>(AValue);
    ftComp: Result := TValue.From<Comp>(AValue);
    ftCurr: Result := TValue.From<Currency>(AValue);
  end;
end;

function TValueHelper.IsFloat: Boolean;
begin
  Result := Kind = tkFloat;
end;

function TValueHelper.IsNumeric: Boolean;
begin
  Result := Kind in [tkInteger, tkChar, tkEnumeration, tkFloat, tkWChar, tkInt64];
end;

function TValueHelper.IsString: Boolean;
begin
  Result := Kind in [tkChar, tkString, tkWChar, tkLString, tkWString, tkUString];
end;

function TValueHelper.TryCastEx(ATypeInfo: PTypeInfo;
  out AResult: TValue): Boolean;
begin
  Result := False;
  if not Result then
  begin
    case Kind of
      tkInteger, tkEnumeration, tkChar, tkWChar, tkInt64:
      begin
        case ATypeInfo.Kind of
          tkInteger, tkEnumeration, tkChar, tkInt64:
          begin
            AResult := TValue.FromOrdinal(ATypeInfo, AsOrdinal);
            Result := True;
          end;
          tkFloat:
          begin
            AResult := TValue.FromFloat(ATypeInfo, AsOrdinal);
            Result := True;
          end;
          tkUString:
          begin
            if TypeInfo = System.TypeInfo(Boolean) then
            begin
              AResult := TValue.From<string>(BoolToStr(AsBoolean, True));
              Result := True;
            end
            else
            begin
              AResult := TValue.From<string>(IntToStr(AsOrdinal));
              Result := True;
            end;
          end;
        end;
      end;
      tkFloat:
      begin
        case ATypeInfo.Kind of
          tkInteger, tkInt64:
          begin
            Result := Frac(AsExtended) = 0;
            if Result then
            begin
              AResult := TValue.FromOrdinal(ATypeInfo, Trunc(AsExtended));
            end;
          end;
          tkUString:
          begin
            if TypeInfo = System.TypeInfo(TDate) then
            begin
              AResult := TValue.From<string>(DateToStr(AsExtended));
              Result := True;
            end
            else
            if TypeInfo = System.TypeInfo(TDateTime) then
            begin
              AResult := TValue.From<string>(DateTimeToStr(AsExtended));
              Result := True;
            end
            else
            if TypeInfo = System.TypeInfo(TTime) then
            begin
              AResult := TValue.From<string>(TimeToStr(AsExtended));
              Result := True;
            end
            else
            begin
              AResult := TValue.From<string>(FloatToStr(AsExtended));
              Result := True;
            end;
          end;
        end;
      end;
      tkUString:
      begin
        case ATypeInfo.Kind of
          tkInteger, tkEnumeration, tkChar, tkInt64:
          begin
            if ATypeInfo = System.TypeInfo(Boolean) then
            begin
              AResult := TValue.From<Boolean>(StrToBoolDef(AsString, False));
              Result := True;
            end
            else
            begin
              AResult := TValue.FromOrdinal(ATypeInfo, StrToIntDef(AsString, 0));
              Result := True;
            end;
          end;
          tkWChar:
          begin
            Result := Length(AsString) = 1;
            if Result then
            begin
              AResult := TValue.From<Char>(AsString[1]);
            end;
          end;
          tkFloat:
          begin
            if ATypeInfo = System.TypeInfo(TDate) then
            begin
              AResult := TValue.From<TDate>(StrToDateDef(AsString, 0));
              Result := True;
            end
            else
            if ATypeInfo = System.TypeInfo(TDateTime) then
            begin
              AResult := TValue.From<TDateTime>(StrToDateTimeDef(AsString, 0));
              Result := True;
            end
            else
            if ATypeInfo = System.TypeInfo(TTime) then
            begin
              AResult := TValue.From<TTime>(StrToTimeDef(AsString, 0));
              Result := True;
            end
            else
            begin
              AResult := TValue.FromFloat(ATypeInfo, StrToFloatDef(AsString, 0));
              Result := True;
            end;
          end;
        end;
      end;
      tkClass:
      begin
        case ATypeInfo.Kind of
          tkInteger, tkEnumeration, tkChar, tkWChar, tkInt64:
          begin
            if ATypeInfo = System.TypeInfo(Boolean) then
            begin
              AResult := TValue.From<Boolean>(AsObject <> nil);
              Result := True;
            end
            else
            begin
              AResult := TValue.FromOrdinal(ATypeInfo, Int64(AsObject));
              Result := True;
            end;
          end;
        end;
      end;
      tkRecord:
      begin
        case ATypeInfo.Kind of
          tkMethod:
          begin
            if TypeInfo = System.TypeInfo(System.TMethod) then
            begin
              TValue.Make(GetReferenceToRawData, ATypeInfo, AResult);
              Result := True;
            end;
          end;
        end;
      end;
{$IFDEF VER210}
      // workaround for bug in RTTI.pas (fixed in XE)
      tkUnknown:
      begin
        case ATypeInfo.Kind of
          tkInteger, tkEnumeration, tkChar, tkWChar, tkInt64:
          begin
            AResult := TValue.FromOrdinal(ATypeInfo, 0);
            Result := True;
          end;
          tkFloat:
          begin
            AResult := TValue.From<Extended>(0);
            Result := True;
          end;
          tkUString:
          begin
            AResult := TValue.From<string>('');
            Result := True;
          end;
        end;
      end;
{$ENDIF}
    end;
  end;
  if not Result then
  begin
    Result := TryCast(ATypeInfo, AResult);
  end;
end;

{ TRttiPropertyHelper }

function TRttiPropertyHelper.GetAttributeOfType<T>: T;
var
  LAttribute: TCustomAttribute;
begin
  Result := nil;
  for LAttribute in GetAttributes do
  begin
    if LAttribute.InheritsFrom(T) then
    begin
      Result := T(LAttribute);
      Break;
    end;
  end;
end;

function TRttiPropertyHelper.GetAttributesOfType<T>: TArray<T>;
var
  LAttribute: TCustomAttribute;
begin
  SetLength(Result, 0);
  for LAttribute in GetAttributes do
  begin
    if LAttribute.InheritsFrom(T) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := T(LAttribute);
    end;
  end;
end;

end.
