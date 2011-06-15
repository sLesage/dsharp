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

unit DSharp.Windows.ColumnDefinitions;

interface

uses
  Classes,
  DSharp.Bindings,
  DSharp.Core.Collections,
  DSharp.Core.DataTemplates,
  Generics.Collections;

const
  CDefaultWidth = 100;

type
  TColumnDefinition = class;

  TCustomDrawEvent = function(Sender: TObject; ColumnDefinition: TColumnDefinition;
    Item: TObject; TargetCanvas: TCanvas; CellRect: TRect;
    ImageList: TCustomImageList; DrawMode: TDrawMode): Boolean of object;
  TGetTextEvent = function(Sender: TObject; ColumnDefinition: TColumnDefinition;
    Item: TObject): string of object;

  TColumnDefinition = class(TCollectionItem)
  private
    FBinding: TBinding;
    FCaption: string;
    FOnCustomDraw: TCustomDrawEvent;
    FOnGetText: TGetTextEvent;
    FWidth: Integer;
    procedure SetCaption(const Value: string);
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property Binding: TBinding read FBinding write FBinding;
    property Caption: string read FCaption write SetCaption;
    property OnCustomDraw: TCustomDrawEvent read FOnCustomDraw write FOnCustomDraw;
    property OnGetText: TGetTextEvent read FOnGetText write FOnGetText;
    property Width: Integer read FWidth write FWidth default CDefaultWidth;
  end;

  TColumnDefinitions = class(TOwnedCollection<TColumnDefinition>)
  protected
    function AddColumn(const ACaption: string; const AWidth: Integer): TColumnDefinition;
  public
    constructor Create(AOwner: TPersistent = nil); override;
  end;

implementation

{ TColumnDefinition }

constructor TColumnDefinition.Create(Collection: TCollection);
begin
  inherited;
  FBinding := TBinding.Create();
  FBinding.BindingMode := bmOneWay;
  FBinding.TargetUpdateTrigger := utExplicit;
  FWidth := CDefaultWidth;
end;

destructor TColumnDefinition.Destroy;
begin
  FBinding.Free();
  inherited;
end;

procedure TColumnDefinition.SetCaption(const Value: string);
begin
  if FCaption = FBinding.SourcePropertyName then
  begin
    FBinding.SourcePropertyName := Value;
  end;
  FCaption := Value;
end;

{ TColumnDefinitions }

constructor TColumnDefinitions.Create(AOwner: TPersistent);
begin
  inherited;
end;

function TColumnDefinitions.AddColumn(
  const ACaption: string; const AWidth: Integer): TColumnDefinition;
begin
  Result := TColumnDefinition.Create(Self);
  Result.Caption := ACaption;
  Result.Width := AWidth;
end;

end.
