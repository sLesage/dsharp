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

unit DSharp.Collections.ObservableCollection;

interface

uses
  DSharp.Collections,
  DSharp.Bindings,
  DSharp.Bindings.Collections,
  DSharp.Core.Events;

type
  TObservableCollection<T: class> = class(TObjectList<T>,
    INotifyCollectionChanged, INotifyPropertyChanged)
  private
    FOnCollectionChanged: TEvent<TCollectionChangedEvent>;
    FOnPropertyChanged: TEvent<TPropertyChangedEvent>;
    function GetOnCollectionChanged: TEvent<TCollectionChangedEvent>;
    function GetOnPropertyChanged: TEvent<TPropertyChangedEvent>;
  protected
    procedure Notify(Value: T; Action: TCollectionChangedAction); override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property OnCollectionChanged: TEvent<TCollectionChangedEvent> read GetOnCollectionChanged;
    property OnPropertyChanged: TEvent<TPropertyChangedEvent> read GetOnPropertyChanged;
  end;

implementation

{ TObservableCollection<T> }

procedure TObservableCollection<T>.AfterConstruction;
begin

end;

procedure TObservableCollection<T>.BeforeDestruction;
begin

end;

function TObservableCollection<T>.GetOnCollectionChanged: TEvent<TCollectionChangedEvent>;
begin
  Result := FOnCollectionChanged.EventHandler;
end;

function TObservableCollection<T>.GetOnPropertyChanged: TEvent<TPropertyChangedEvent>;
begin
  Result := FOnPropertyChanged.EventHandler;
end;

procedure TObservableCollection<T>.Notify(Value: T; Action: TCollectionChangedAction);
begin
  FOnCollectionChanged.Invoke(Self, Value, Action);
  inherited;
  FOnPropertyChanged.Invoke(Self, 'Count');
end;

end.
