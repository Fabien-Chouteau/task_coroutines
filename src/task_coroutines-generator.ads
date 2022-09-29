private with Ada.Synchronous_Task_Control;

generic
   type T is private;
package Task_Coroutines.Generator
with Preelaborate
is

   type Inner_Control is tagged limited private;

   procedure Yield (This : in out Inner_Control; Val : T);

   type Instance
   is tagged limited private
     with Iterable => (First       => First,
                       Next        => Next,
                       Has_Element => Has_Element,
                       Element     => Element);

   type Generator_Proc is access procedure (Ctrl : in out Inner_Control'Class);

   procedure Start (This : aliased in out Instance;
                    Proc : not null Generator_Proc);
   procedure Stop (This : in out Instance);
   function  Done (This : Instance) return Boolean;

   -- Iterable --

   type Cursor_Type is null record;

   function Has_Next (This : in out Instance) return Boolean;

   function Next (This : in out Instance) return T;
   function First (This : Instance) return Cursor_Type;
   function Next (This : in out Instance; C : Cursor_Type) return Cursor_Type;
   function Has_Element (This : in out Instance; C : Cursor_Type)
                         return Boolean;
   function Element (This : in out Instance; C : Cursor_Type) return T;

private

   type Inner_Acc is access all Inner_Control'Class;
   type Outer_Acc is access all Instance'Class;

   task type Coro_Task is
      entry Start (Inner : not null Inner_Acc;
                   Proc  : not null Generator_Proc);
   end Coro_Task;

   type State_Type is (Waiting, Yielding, Done);

   type Instance
   is tagged limited record
      T : Coro_Task;
      Suspend : Ada.Synchronous_Task_Control.Suspension_Object;

      Inner : aliased Inner_Control;
   end record;

   type Inner_Control
   is tagged limited record
      Outer : Outer_Acc;
      State : State_Type := Waiting;
      Val   : T;
      Suspend : Ada.Synchronous_Task_Control.Suspension_Object;
   end record;

end Task_Coroutines.Generator;
