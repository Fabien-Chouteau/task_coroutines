private with Ada.Synchronous_Task_Control;

package Task_Coroutines.Coroutine
with Preelaborate
is

   type Inner_Control
   is tagged limited private;

   procedure Yield (This : in out Inner_Control);

   function Clock (This : Inner_Control) return Duration;

   procedure Delay_Seconds (This : in out Inner_Control; Dur : Duration);

   generic
      with function Wait_Cond return Boolean;
   procedure Wait_For (This : in out Inner_Control);

   type Instance
   is tagged limited private;

   type Coro_Proc is access procedure (Ctrl : in out Inner_Control'Class);

   procedure Start (This : aliased in out Instance;
                    Proc : not null Coro_Proc);

   procedure Stop (This : in out Instance);
   procedure Poll (This : in out Instance; Dt : Duration := 0.0);
   function  Done (This : Instance) return Boolean;

private

   type Inner_Acc is access all Inner_Control'Class;
   type Outer_Acc is access all Instance'Class;

   task type Coro_Task is
      entry Start (Inner : not null Inner_Acc;
                   Proc  : not null Coro_Proc);
   end Coro_Task;

   type Instance
   is tagged limited record
      T : Coro_Task;
      Is_Done : Boolean := False;

      Suspend : Ada.Synchronous_Task_Control.Suspension_Object;

      Inner : aliased Inner_Control;
   end record;

   type Inner_Control
   is tagged limited record
      Outer : Outer_Acc;
      Time : Duration;
      Suspend : Ada.Synchronous_Task_Control.Suspension_Object;
   end record;

end Task_Coroutines.Coroutine;
