/* $OpenBSD: cmd-move-window.c,v 1.31 2020/04/13 10:59:58 nicm Exp $ */

/*
 * Copyright (c) 2008 Nicholas Marriott <nicholas.marriott@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>

#include <stdlib.h>

#include "tmux.h"

/*
 * Move a window.
 */

static enum cmd_retval	cmd_move_window_exec(struct cmd *, struct cmdq_item *);

const struct cmd_entry cmd_move_window_entry = {
	.name = "move-window",
	.alias = "movew",

	.args = { "adkrs:t:", 0, 0 },
	.usage = "[-dkr] " CMD_SRCDST_WINDOW_USAGE,

	.source = { 's', CMD_FIND_WINDOW, 0 },
	/* -t is special */

	.flags = 0,
	.exec = cmd_move_window_exec
};

const struct cmd_entry cmd_link_window_entry = {
	.name = "link-window",
	.alias = "linkw",

	.args = { "adks:t:", 0, 0 },
	.usage = "[-dk] " CMD_SRCDST_WINDOW_USAGE,

	.source = { 's', CMD_FIND_WINDOW, 0 },
	/* -t is special */

	.flags = 0,
	.exec = cmd_move_window_exec
};

static enum cmd_retval
cmd_move_window_exec(struct cmd *self, struct cmdq_item *item)
{
	struct args		*args = cmd_get_args(self);
	struct cmd_find_state	*source = cmdq_get_source(item);
	struct cmd_find_state	 target;
	const char		*tflag = args_get(args, 't');
	struct session		*src;
	struct session		*dst;
	struct winlink		*wl;
	char			*cause;
	int			 idx, kflag, dflag, sflag;

	if (args_has(args, 'r')) {
		if (cmd_find_target(&target, item, tflag, CMD_FIND_SESSION,
		    CMD_FIND_QUIET) != 0)
			return (CMD_RETURN_ERROR);

		session_renumber_windows(target.s);
		recalculate_sizes();
		server_status_session(target.s);

		return (CMD_RETURN_NORMAL);
	}
	if (cmd_find_target(&target, item, tflag, CMD_FIND_WINDOW,
	    CMD_FIND_WINDOW_INDEX) != 0)
		return (CMD_RETURN_ERROR);
	src = source->s;
	dst = target.s;
	wl = source->wl;
	idx = target.idx;

	kflag = args_has(args, 'k');
	dflag = args_has(args, 'd');
	sflag = args_has(args, 's');

	if (args_has(args, 'a')) {
		if ((idx = winlink_shuffle_up(dst, dst->curw)) == -1)
			return (CMD_RETURN_ERROR);
	}

	if (server_link_window(src, wl, dst, idx, kflag, !dflag, &cause) != 0) {
		cmdq_error(item, "can't link window: %s", cause);
		free(cause);
		return (CMD_RETURN_ERROR);
	}
	if (cmd_get_entry(self) == &cmd_move_window_entry)
		server_unlink_window(src, wl);

	/*
	 * Renumber the winlinks in the src session only, the destination
	 * session already has the correct winlink id to us, either
	 * automatically or specified by -s.
	 */
	if (!sflag && options_get_number(src->options, "renumber-windows"))
		session_renumber_windows(src);

	recalculate_sizes();

	return (CMD_RETURN_NORMAL);
}
