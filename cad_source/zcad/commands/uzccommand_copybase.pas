{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.txt, included in this distribution,                 *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
}
{$MODE OBJFPC}{$H+}
unit uzccommand_CopyBase;
{$INCLUDE zengineconfig.inc}

interface
uses
  Varman,
  gzctnrVectorTypes,
  uzcdrawings,
  uzeutils,
  uzglviewareadata,
  uzccommandsabstract,uzccommandsimpl,
  uzccommand_copy,
  uzegeometry,
  uzccommandsmanager,
  uzegeometrytypes,uzeentity,uzcLog,
  uzcstrconsts,uzeconsts,
  uzcinterface,
  uzgldrawcontext,
  uzccommand_copyclip,
  uzeentwithlocalcs;

type
  {REGISTEROBJECTTYPE copybase_com}
  copybase_com =  object(CommandRTEdObject)
    procedure CommandStart(Operands:TCommandOperands); virtual;
    function BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; var button: Byte;osp:pos_record): Integer; virtual;
  end;
var
  copybase:copybase_com;

implementation

procedure copybase_com.CommandStart(Operands:TCommandOperands);
var //i: Integer;
  {tv,}pobj: pGDBObjEntity;
      ir:itrec;
      counter:integer;
      //tcd:TCopyObjectDesc;
begin
  inherited;

  counter:=0;

  pobj:=drawings.GetCurrentROOT^.ObjArray.beginiterate(ir);
  if pobj<>nil then
  repeat
    if pobj^.selected then
    inc(counter);
  pobj:=drawings.GetCurrentROOT^.ObjArray.iterate(ir);
  until pobj=nil;


  if counter>0 then
  begin
  drawings.GetCurrentDWG^.wa.SetMouseMode((MGet3DPoint) or (MMoveCamera) or (MRotateCamera));
  ZCMsgCallBackInterface.TextMessage(rscmBasePoint,TMWOHistoryOut);
  end
  else
  begin
    ZCMsgCallBackInterface.TextMessage(rscmSelEntBeforeComm,TMWOHistoryOut);
    Commandmanager.executecommandend;
  end;
end;
function copybase_com.BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; var button: Byte;osp:pos_record): Integer;
var
    dist:gdbvertex;
    dispmatr:DMatrix4D;
    ir:itrec;
    //pcd:PTCopyObjectDesc;

    //pbuf:pchar;
    //hgBuffer:HGLOBAL;

    //s,suni:String;
    //I:Integer;
      tv,pobj: pGDBObjEntity;
      DC:TDrawContext;
      NeedReCreateClipboardDWG:boolean;
begin

      //drawings.GetCurrentDWG^.ConstructObjRoot.ObjMatrix:=dispmatr;
  NeedReCreateClipboardDWG:=true;
  if (button and MZW_LBUTTON)<>0 then
  begin
      ClipboardDWG^.pObjRoot^.ObjArray.free;
      dist.x := -wc.x;
      dist.y := -wc.y;
      dist.z := -wc.z;

      dispmatr:=onematrix;
      PGDBVertex(@dispmatr[3])^:=dist;

   dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
   pobj:=drawings.GetCurrentROOT^.ObjArray.beginiterate(ir);
   if pobj<>nil then
   repeat
          begin
              if pobj^.selected then
              begin
                if NeedReCreateClipboardDWG then
                                                 begin
                                                      ReCreateClipboardDWG;
                                                      NeedReCreateClipboardDWG:=false;
                                                 end;
                tv:=drawings.CopyEnt(drawings.GetCurrentDWG,ClipboardDWG,pobj);
                if tv^.IsHaveLCS then
                                    PGDBObjWithLocalCS(tv)^.CalcObjMatrix;
                tv^.transform(dispmatr);
                tv^.FormatEntity(ClipboardDWG^,dc);
              end;
          end;
          pobj:=drawings.GetCurrentROOT^.ObjArray.iterate(ir);
   until pobj=nil;

   CopyToClipboard;

   drawings.GetCurrentDWG^.ConstructObjRoot.ObjMatrix:=onematrix;
   commandend;
   commandmanager.executecommandend;
  end;
  result:=cmd_ok;
end;


procedure startup;
begin
  copybase.init('CopyBase',CADWG or CASelEnts,0);
end;
procedure Finalize;
begin
end;
initialization
  programlog.LogOutFormatStr('Unit "%s" initialization',[{$INCLUDE %FILE%}],LM_Info,UnitsInitializeLMId);
  startup;
finalization
  ProgramLog.LogOutFormatStr('Unit "%s" finalization',[{$INCLUDE %FILE%}],LM_Info,UnitsFinalizeLMId);
  finalize;
end.
