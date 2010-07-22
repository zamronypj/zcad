{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
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

unit UGDBOpenArrayOfPV;
{$INCLUDE def.inc}
interface
uses log,gdbasetypes{,math},UGDBOpenArrayOfPObjects,GDBEntity{,UGDBOpenArray, oglwindowdef},sysutils,
     gdbase, geometry, {OGLtypes, oglfunc,} {varmandef,gdbobjectsconstdef,}memman;
type
objvizarray = array[0..0] of PGDBObjEntity;
pobjvizarray = ^objvizarray;
PGDBObjEntityArray=^GDBObjEntityArray;
GDBObjEntityArray=array [0..0] of PGDBObjEntity;
{Export+}
PGDBObjOpenArrayOfPV=^GDBObjOpenArrayOfPV;
GDBObjOpenArrayOfPV=object(GDBOpenArrayOfPObjects)
                      procedure DrawWithattrib;virtual;
                      procedure DrawGeometry(lw:GDBInteger);virtual;
                      procedure DrawOnlyGeometry(lw:GDBInteger);virtual;
                      procedure renderfeedbac;virtual;
                      function calcvisible(frustum:ClipArray):GDBBoolean;virtual;
                      function CalcTrueInFrustum(frustum:ClipArray):TInRect;virtual;
                      function DeSelect:GDBInteger;virtual;
                      function CreateObj(t: GDBByte;owner:GDBPointer):PGDBObjEntity;virtual;
                      function CreateInitObj(t: GDBByte;owner:GDBPointer):PGDBObjEntity;virtual;
                      function calcbb:GDBBoundingBbox;
                      function calcvisbb:GDBBoundingBbox;
                      function getoutbound:GDBBoundingBbox;
                      function getonlyoutbound:GDBBoundingBbox;
                      procedure Format;virtual;
                      procedure FormatAfterEdit;virtual;
                      function InRect:TInRect;virtual;
                end;
{Export-}
implementation
uses {UGDBDescriptor,}GDBManager;
function GDBObjOpenArrayOfPV.inrect;
var pobj:pGDBObjEntity;
    ir:itrec;
    fr:TInRect;
    all:boolean;
begin
     all:=true;
     pobj:=beginiterate(ir);
     if pobj<>nil then
                       repeat
                             fr:=pobj^.InRect;
                             if fr<>IRFully then
                                                begin
                                                     all:=false;
                                                     if fr=IRPartially then
                                                                           begin
                                                                                result:=IRPartially;
                                                                                exit;
                                                                           end;
                                                end;
                             pobj:=iterate(ir);
                       until pobj=nil;
    if all then
               result:=IRFully
           else
               result:=IREmpty;
end;
function GDBObjOpenArrayOfPV.calcbb:GDBBoundingBbox;
var pobj:pGDBObjEntity;
    ir:itrec;
begin
  pobj:=beginiterate(ir);
  if pobj=nil then
                  begin
                       result.LBN:=NulVertex;
                       result.RTF:=NulVertex;
                  end
              else
                  begin
                       result:=pobj^.vp.BoundingBox;
                       pobj:=iterate(ir);
                       if pobj<>nil then
                       repeat
                             concatbb(result,pobj^.vp.BoundingBox);
                             pobj:=iterate(ir);
                       until pobj=nil;
                  end;
end;
function GDBObjOpenArrayOfPV.calcvisbb:GDBBoundingBbox;
var pobj:pGDBObjEntity;
    ir:itrec;
begin
     result.LBN:=NulVertex;
     result.RTF:=NulVertex;

     pobj:=beginiterate(ir);
     if pobj<>nil then
     repeat
           if pobj^.infrustum then
           begin
                result:=pobj^.vp.BoundingBox;
                       pobj:=iterate(ir);
                       if pobj<>nil then
                       repeat
                             if pobj^.infrustum then
                             begin
                                  concatbb(result,pobj^.vp.BoundingBox);
                             end;
                             pobj:=iterate(ir);
                       until pobj=nil;
           end;
           pobj:=iterate(ir);
     until pobj=nil;
end;

function GDBObjOpenArrayOfPV.getoutbound:GDBBoundingBbox;
var pobj:pGDBObjEntity;
    ir:itrec;
begin
  pobj:=beginiterate(ir);
  if pobj=nil then
                  begin
                       result.LBN:=NulVertex;
                       result.RTF:=NulVertex;
                  end
              else
                  begin
                       pobj^.getoutbound;
                       result:=pobj.vp.BoundingBox;
                       pobj^.correctbb;
                       pobj:=iterate(ir);
                       if pobj<>nil then
                       repeat
                             pobj^.getoutbound;
                             concatbb(result,pobj^.vp.BoundingBox);
                             pobj^.correctbb;
                             pobj:=iterate(ir);
                       until pobj=nil;
                  end;
end;
function GDBObjOpenArrayOfPV.getonlyoutbound:GDBBoundingBbox;
var pobj:pGDBObjEntity;
    ir:itrec;
begin
  pobj:=beginiterate(ir);
  if pobj=nil then
                  begin
                       result.LBN:=NulVertex;
                       result.RTF:=NulVertex;
                  end
              else
                  begin
                       pobj^.getonlyoutbound;
                       result:=pobj.vp.BoundingBox;
                       //pobj^.correctbb;
                       pobj:=iterate(ir);
                       if pobj<>nil then
                       repeat
                             pobj^.getonlyoutbound;
                             concatbb(result,pobj^.vp.BoundingBox);
                             //pobj^.correctbb;
                             pobj:=iterate(ir);
                       until pobj=nil;
                  end;
end;
function GDBObjOpenArrayOfPV.CreateObj(t: GDBByte;owner:GDBPointer): PGDBObjEntity;
var temp: PGDBObjEntity;
begin
  temp := nil;
  if count=max then
                   self.grow;
  if count<max then
  begin
  temp:=CreateObjFree(t);
  temp^.bp.Owner:=owner;
  add(@temp);
  end;
  result := temp;
end;
function GDBObjOpenArrayOfPV.CreateInitObj(t: GDBByte;owner:GDBPointer): PGDBObjEntity;
var temp: PGDBObjEntity;
begin
  temp := nil;
  //if count<max then
  begin
  temp:=CreateInitObjfree(t,owner);
  add(@temp);
  end;
  result := temp;
end;
function GDBObjOpenArrayOfPV.DeSelect;
var
  p:pGDBObjEntity;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.DeSelect;
       p:=iterate(ir);
  until p=nil;
end;
procedure GDBObjOpenArrayOfPV.format;
var
  p:pGDBObjEntity;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.format;
       p:=iterate(ir);
  until p=nil;
end;
procedure GDBObjOpenArrayOfPV.formatafteredit;
var
  p:pGDBObjEntity;
      ir:itrec;
begin
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       p^.formatafteredit;
       p:=iterate(ir);
  until p=nil;
end;
procedure GDBObjOpenArrayOfPV.renderfeedbac;
var
  p:pGDBObjEntity;
      ir:itrec;
begin
  if count>500 then
                   count:=count;
  p:=beginiterate(ir);
  if p<>nil then
  repeat
  if ir.itc=12 then
                         count:=count;

  {if p^.vp.ID=0 then
                         p^.vp.ID:=p^.vp.ID;}
       if (p^.infrustum)or(p^.Selected) then
                                            begin
                                                 {$IFDEF TOTALYLOG}programlog.logoutstr(p^.GetObjTypeName+'.renderfeedback',0);{$ENDIF}
                                                 p^.renderfeedback;
                                            end;
       p:=iterate(ir);
  until p=nil;
end;
procedure GDBObjOpenArrayOfPV.DrawWithattrib;
var
  p:pGDBObjEntity;
      ir:itrec;
begin
  if Count>1 then
                    Count:=Count;
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       if p^.vp.ID<>0 then
                         //p^.vp.ID:=p^.vp.ID;
       if p^.infrustum then
                           p^.DrawWithAttrib;
       p:=iterate(ir);
  until p=nil;
end;
procedure GDBObjOpenArrayOfPV.DrawGeometry;
var
  p:pGDBObjEntity;
      ir:itrec;
begin
  if Count>1 then
                    Count:=Count;
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       if p^.vp.ID<>0 then
                         //p^.vp.ID:=p^.vp.ID;
       if p^.infrustum then
                           p^.DrawGeometry(lw);
       p:=iterate(ir);
  until p=nil;
end;
procedure GDBObjOpenArrayOfPV.DrawOnlyGeometry;
var
  p:pGDBObjEntity;
      ir:itrec;
begin
  if Count>1 then
                    Count:=Count;
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       if p^.vp.ID<>0 then
                         //p^.vp.ID:=p^.vp.ID;
       if p^.infrustum then
                           p^.DrawOnlyGeometry(lw);
       p:=iterate(ir);
  until p=nil;
end;
function GDBObjOpenArrayOfPV.calcvisible;
var
  p:pGDBObjEntity;
  q:GDBBoolean;
      ir:itrec;
begin
  result:=false;
  p:=beginiterate(ir);
  if p<>nil then
  repeat
       q:=p^.calcvisible(frustum);
       result:=result or q;
       p:=iterate(ir);
  until p=nil;
end;
function GDBObjOpenArrayOfPV.CalcTrueInFrustum;
var
  p:pGDBObjEntity;
  q:TInRect;
  ir:itrec;
  emptycount,objcount:integer;
begin
  emptycount:=0;
  objcount:=0;
  result:=IREmpty;
  p:=beginiterate(ir);
  if p<>nil then
  begin
  repeat
        if p^.Visible then
        begin
             inc(objcount);
             q:=p^.CalcTrueInFrustum(frustum);

    if q=IREmpty then
                            begin
                                 inc(emptycount);
                            end;
     if q=IRPartially then
                                  begin
                                       result:=IRPartially;
                                       exit;
                                  end;
     if (q=IRFully)and(emptycount>0) then
                                  begin
                                       result:=IRPartially;
                                       exit;
                                  end;
        end;
        p:=iterate(ir);
  until p=nil;
     if (emptycount=0)and(objcount>0) then
                       result:=IRFully
                     else
                       result:=IREmpty;
  end;
end;
begin
  {$IFDEF DEBUGINITSECTION}LogOut('UGDBOpenArrayOfPV.initialization');{$ENDIF}
end.
