with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with Ada.Task_Identification;

package body Task_Coroutines.Coroutine is

   -----------
   -- Yield --
   -----------

   procedure Yield (This : in out Inner_Control) is
   begin
      Set_False (This.Suspend);

      --  Wake up the outer task
      Set_True (This.Outer.Suspend);

      --  Wait until the outer task wakes us up
      Suspend_Until_True (This.Suspend);
   end Yield;

   -----------
   -- Clock --
   -----------

   function Clock (This : Inner_Control) return Duration is
   begin
      return This.Time;
   end Clock;

   -------------------
   -- Delay_Seconds --
   -------------------

   procedure Delay_Seconds (This : in out Inner_Control; Dur : Duration) is
      Expire_Time : constant Duration := This.Clock + Dur;
   begin
      while This.Clock < Expire_Time loop
         This.Yield;
      end loop;
   end Delay_Seconds;

   --------------
   -- Wait_For --
   --------------

   procedure Wait_For (This : in out Inner_Control) is
   begin
      while not Wait_Cond loop
         This.Yield;
      end loop;
   end Wait_For;

   -----------
   -- Start --
   -----------

   procedure Start (This : aliased in out Instance;
                    Proc : not null Coro_Proc)
   is
   begin
      Set_False (This.Suspend);

      This.Inner.Outer := This'Unchecked_Access;
      This.T.Start (This.Inner'Unchecked_Access, Proc);

      Suspend_Until_True (This.Suspend);
   end Start;

   ----------
   -- Stop --
   ----------

   procedure Stop (This : in out Instance) is
   begin
      Ada.Task_Identification.Abort_Task (This.T'Identity);
      This.Is_Done := True;
   end Stop;

   ----------
   -- Poll --
   ----------

   procedure Poll (This : in out Instance; Dt : Duration := 0.0) is
   begin
      if This.Done then
         return;
      end if;

      This.Inner.Time := This.Inner.Time + Dt;
      Set_True (This.Inner.Suspend);
      Suspend_Until_True (This.Suspend);
   end Poll;

   ----------
   -- Done --
   ----------

   function Done (This : Instance) return Boolean is
   begin
      return This.Is_Done;
   end Done;

   ---------------
   -- Coro_Task --
   ---------------

   task body Coro_Task is
      Ctrl : Inner_Acc;
      Proc : Coro_Proc := null;
   begin
      Ctrl := null;
      Proc := null;

      select
         accept Start (Inner : not null Inner_Acc;
                       Proc  : not null Coro_Proc) do
            Ctrl := Inner;
            Coro_Task.Proc := Start.Proc;
         end Start;
      or
         terminate;
      end select;

      Ctrl.Time := 0.0;

      declare
      begin
         Proc (Ctrl.all);
      exception
         when others =>
            null;
      end;

      Ctrl.Outer.Is_Done := True;
      Set_True (Ctrl.Outer.Suspend);
   end Coro_Task;

end Task_Coroutines.Coroutine;
