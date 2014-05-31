/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */

using Gee;

public class SudokuGame
{
    public SudokuBoard board;
    public GLib.Timer timer;

    private struct UndoItem
    {
        public int row;
        public int col;
        public int val;
    }

    public signal void cell_changed (int row, int col, int old_val, int new_val);

    private SList<UndoItem?> undostack;
    private SList<UndoItem?> redostack;

    public bool is_undostack_null ()
    {
        return undostack == null;
    }

    public bool is_redostack_null ()
    {
        return redostack == null;
    }

    public SudokuGame (SudokuBoard board)
    {
        this.board = board;
        timer = new Timer();
        undostack = null;
        redostack = null;
    }

    public void insert (int row, int col, int val)
    {
        var old_val = board[row, col];
        update_undo (row, col, old_val, val);
        board.insert (row, col, val);
        cell_changed (row, col, old_val, val);
    }

    public void remove (int row, int col)
    {
        int old_val = board[row, col];
        update_undo (row, col, old_val, 0);
        board.remove (row, col);
        cell_changed (row, col, old_val, 0);
    }

    public void undo ()
    {
        apply_stack (ref undostack, ref redostack);
    }

    public void redo ()
    {
        apply_stack (ref redostack, ref undostack);
    }

    public void reset ()
    {
        timer.reset();
        var count = board.filled;
        for (var l1 = 0; l1 < board.rows; l1++)
        {
            for (var l2 = 0; l2 < board.cols; l2++)
            {
                if (!board.is_fixed[l1, l2])
                    remove (l1, l2);
            }
        }
        count -= board.filled;
        add_to_stack (ref undostack, -1, -1, count);
    }

    public void cell_changed_cb (int row, int col, int old_val, int new_val)
    {
        cell_changed (row, col, old_val, new_val);
    }

    public void update_undo (int row, int col, int old_val, int new_val)
    {
        add_to_stack (ref undostack, row, col, old_val);
        redostack = null;
    }

    private void add_to_stack (ref SList<UndoItem?> stack, int r, int c, int v)
    {
        UndoItem step = { r, c, v };
        stack.prepend (step);
    }

    private void apply_stack (ref SList<UndoItem?> from, ref SList<UndoItem?> to)
    {
        if (from == null)
            return;

        /* Undoing change of single cell */
        if (from.data.row >= 0 && from.data.col >= 0)
        {
            int old_val = board [from.data.row, from.data.col];
            add_to_stack (ref to, from.data.row, from.data.col, old_val);
            board.remove (from.data.row, from.data.col);
            if (from.data.val != 0) {
                board.insert (from.data.row, from.data.col, from.data.val);
            }
            cell_changed (from.data.row, from.data.col, old_val, from.data.val);
            from.remove (from.data);
        }
        /* Undoing reset action */
        else
        {
            var num = from.data.val;
            from.remove (from.data);
            for (var l = 0; l < num; l++)
                apply_stack (ref from, ref to);
            add_to_stack (ref to, -1, -1, num);
        }
    }

    public double get_total_time_played ()
    {
        return board.previous_played_time + timer.elapsed ();
    }
}