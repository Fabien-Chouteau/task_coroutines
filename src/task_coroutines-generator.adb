with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

with Ada.Task_Identification;

package body Task_Coroutines.Generator is

   -----------
   -- Yield --
   -----------

   procedure Yield (This : in out Inner_Control; Val : T) is
   begin
      This.Val := Val;

      Set_False (This.Suspend);

      This.State := Yielding;

      --  Wake up the outer task
      Set_True (This.Outer.Suspend);

      --  Wait until the outer task wakes us up
      Suspend_Until_True (This.Suspend);
   end Yield;

   -----------
   -- Start --
   -----------

   procedure Start (This : aliased in out Instance;
                    Proc : not null Generator_Proc)
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
      This.Inner.State := Done;
   end Stop;

   ----------
   -- Done --
   ----------

   function Done (This : Instance) return Boolean is
   begin
      return This.Inner.State = Done;
   end Done;

   --------------
   -- Has_Next --
   --------------

   function Has_Next (This : in out Instance) return Boolean is
   begin

      case This.Inner.State is
         when Waiting =>
            null;
         when Yielding =>
            return True;
         when Done =>
            return False;
      end case;

      Set_False (This.Suspend);

      Set_True (This.Inner.Suspend);

      Suspend_Until_True (This.Suspend);

      case This.Inner.State is
         when Waiting =>
            raise Program_Error with "Unreachable state";
         when Yielding =>
            return True;
         when Done =>
            return False;
      end case;
   end Has_Next;

   ----------
   -- Next --
   ----------

   function Next (This : in out Instance) return T is
   begin
      case This.Inner.State is
         when Waiting | Done =>
            raise Program_Error with "Unreachable state";
         when Yielding =>
            This.Inner.State := Waiting;
            return This.Inner.Val;
      end case;
   end Next;

   -----------
   -- First --
   -----------

   function First (This : Instance) return Cursor_Type is
      pragma Unreferenced (This);
   begin
      return (null record);
   end First;

   ----------
   -- Next --
   ----------

   function Next (This : in out Instance; C : Cursor_Type)
                  return Cursor_Type
   is
   begin
      case This.Inner.State is
         when Waiting =>
            null;
         when Yielding =>
            This.Inner.State := Waiting;
         when Done =>
            raise Program_Error with "Unreachable state";
      end case;
      return This.First;
   end Next;

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element (This : in out Instance; C : Cursor_Type)
                         return Boolean
   is
   begin
      return This.Has_Next;
   end Has_Element;

   -------------
   -- Element --
   -------------

   function Element (This : in out Instance; C : Cursor_Type) return T is
   begin
      case This.Inner.State is
         when Waiting | Yielding =>
            This.Inner.State := Waiting;
            return This.Inner.Val;
         when Done =>
            raise Program_Error with "Unreachable state";
      end case;
   end Element;

   ---------------
   -- Coro_Task --
   ---------------

   task body Coro_Task is
      Ctrl : Inner_Acc;
      Proc : Generator_Proc;
   begin
      loop

         Ctrl := null;
         Proc := null;

         select
            accept Start (Inner : not null Inner_Acc;
                          Proc  : not null Generator_Proc) do
               Ctrl := Inner;
               Coro_Task.Proc := Start.Proc;
            end Start;
         or
            terminate;
         end select;

         declare
         begin
            Proc (Ctrl.all);
         exception
            when others =>
               null;
         end;

         Ctrl.State := Done;
         Set_True (Ctrl.Outer.Suspend);
      end loop;
   end Coro_Task;

end Task_Coroutines.Generator;
