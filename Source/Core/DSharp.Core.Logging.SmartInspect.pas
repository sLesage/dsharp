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

unit DSharp.Core.Logging.SmartInspect;

interface

uses
  DSharp.Core.Logging;

type
  TSmartInspectLogging = class(TBaseLogging)
  protected
    procedure LogEntry(const ALogEntry: TLogEntry); override;
  end;

implementation

uses
  DSharp.Core.Logging.SmartInspect.Helper,
  SiAuto,
  SysUtils;

{ TSmartInspectLogging }

procedure TSmartInspectLogging.LogEntry(const ALogEntry: TLogEntry);
begin
  case ALogEntry.LogKind of
    lkEnterMethod:
    begin
      if not ALogEntry.Value.IsEmpty then
      begin
        if ALogEntry.Value.IsClass then
          SiMain.EnterMethod(ALogEntry.Value.AsClass.ClassName + '.' + ALogEntry.Name)
        else if ALogEntry.Value.IsObject then
          SiMain.EnterMethod(ALogEntry.Value.AsObject, ALogEntry.Name)
      end
      else
        SiMain.EnterMethod(ALogEntry.Name);
    end;
    lkLeaveMethod:
    begin
      if not ALogEntry.Value.IsEmpty then
      begin
        if ALogEntry.Value.IsClass then
          SiMain.LeaveMethod(ALogEntry.Value.AsClass.ClassName + '.' + ALogEntry.Name)
        else if ALogEntry.Value.IsObject then
          SiMain.LeaveMethod(ALogEntry.Value.AsObject, ALogEntry.Name)
      end
      else
        SiMain.LeaveMethod(ALogEntry.Name);
    end;
    lkMessage:
    begin
       SiMain.LogMessage(ALogEntry.Name);
    end;
    lkException:
    begin
      SiMain.LogException(ALogEntry.Value.AsType<Exception>, ALogEntry.Name);
    end;
    lkValue:
    begin
      SiMain.LogValue(ALogEntry.Name, ALogEntry.Value);
    end;
  end;
end;

initialization
  Si.Enabled := True;
  RegisterLogging(TSmartInspectLogging.Create);

end.