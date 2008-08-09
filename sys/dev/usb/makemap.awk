#! /usr/bin/awk -f
#	$OpenBSD: makemap.awk,v 1.9 2008/08/09 16:31:08 miod Exp $
#
# Copyright (c) 2005, Miodrag Vallat
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#
# This script attempts to convert, with minimal hacks and losses, the
# regular PS/2 keyboard (pckbd) layout tables into USB keyboard (ukbd)
# layout tables.
#

BEGIN {
	rcsid = "$OpenBSD: makemap.awk,v 1.9 2008/08/09 16:31:08 miod Exp $"
	ifdepth = 0
	ignore = 0
	declk = 0
	haskeys = 0
	kbfr = 0
	nmaps = 0

	# PS/2 id -> UKBD conversion table, or "sanity lossage 101"
	for (i = 0; i < 256; i++)
		conv[i] = -1

	conv[1] = 41
	conv[2] = 30
	conv[3] = 31
	conv[4] = 32
	conv[5] = 33
	conv[6] = 34
	conv[7] = 35
	conv[8] = 36
	conv[9] = 37
	conv[10] = 38
	conv[11] = 39
	conv[12] = 45
	conv[13] = 46
	conv[14] = 42
	conv[15] = 43
	conv[16] = 20
	conv[17] = 26
	conv[18] = 8
	conv[19] = 21
	conv[20] = 23
	conv[21] = 28
	conv[22] = 24
	conv[23] = 12
	conv[24] = 18
	conv[25] = 19
	conv[26] = 47
	conv[27] = 48
	conv[28] = 40
	conv[29] = 224
	conv[30] = 4
	conv[31] = 22
	conv[32] = 7
	conv[33] = 9
	conv[34] = 10
	conv[35] = 11
	conv[36] = 13
	conv[37] = 14
	conv[38] = 15
	conv[39] = 51
	conv[40] = 52
	conv[41] = 53
	conv[42] = 225
	conv[43] = 50
	conv[44] = 29
	conv[45] = 27
	conv[46] = 6
	conv[47] = 25
	conv[48] = 5
	conv[49] = 17
	conv[50] = 16
	conv[51] = 54
	conv[52] = 55
	conv[53] = 56
	conv[54] = 229
	conv[55] = 85
	conv[56] = 226
	conv[57] = 44
	conv[58] = 57
	conv[59] = 58
	conv[60] = 59
	conv[61] = 60
	conv[62] = 61
	conv[63] = 62
	conv[64] = 63
	conv[65] = 64
	conv[66] = 65
	conv[67] = 66
	conv[68] = 67
	conv[69] = 83
	conv[70] = 71
	conv[71] = 95
	conv[72] = 96
	conv[73] = 97
	conv[74] = 86
	conv[75] = 92
	conv[76] = 93
	conv[77] = 94
	conv[78] = 87
	conv[79] = 89
	conv[80] = 90M
	conv[81] = 91
	conv[82] = 98
	conv[83] = 99
	conv[86] = 100
	conv[87] = 68
	conv[88] = 69
	conv[112] = 135
	conv[115] = 136
	conv[121] = 137
	conv[123] = 138
	conv[125] = 139
	conv[127] = 72
	conv[156] = 88
	conv[157] = 228
	conv[170] = 70
	conv[181] = 84
	conv[184] = 230
	# 198 is #if 0 in the PS/2 map...
	conv[199] = 74
	conv[200] = 82
	conv[201] = 75
	conv[203] = 80
	conv[205] = 79
	conv[207] = 77
	conv[208] = 81
	conv[209] = 78
	conv[210] = 73
	conv[211] = 99
	conv[219] = 227
	conv[220] = 231
	conv[221] = 101
}
NR == 1 {
	VERSION = $0
	gsub("\\$", "", VERSION)
	gsub("\\$", "", rcsid)

	printf("/*\t\$OpenBSD\$\t*/\n\n")
	printf("/*\n")
	printf(" * THIS FILE IS AUTOMAGICALLY GENERATED.  DO NOT EDIT.\n")
	printf(" *\n")
	printf(" * generated by:\n")
	printf(" *\t%s\n", rcsid)
	printf(" * generated from:\n")
	printf(" */\n")
	print VERSION

	next
}

#
# A very limited #if ... #endif parser. We only want to correctly detect
# ``#if 0'' constructs, so as not to process their contents. This is necessary
# since our output is out-of-order from our input.
#
# Note that this does NOT handle ``#ifdef notyet'' correctly - please only use
# ``#if 0'' constructs in the input.
#

/^#if/ {
	ignores[ifdepth] = ignore
	if ($2 == "0")
		ignore = 1
	else
		ignore = 0
	ifdepth++
	if (ignore)
		next
}
/^#endif/ {
	oldignore = ignore
	ifdepth--
	ignore = ignores[ifdepth]
	ignores[ifdepth] = 0
	if (oldignore)
		next
}

$1 == "#include" {
	if (ignore)
		next
	if ($2 == "<dev/pckbc/wskbdmap_mfii.h>")
		next
	printf("#include %s\n", $2)
	next
}
$1 == "#define" || $1 == "#undef" {
	if (ignore)
		next
	print $0
	next
}

# Don't bother converting the DEC LK layout.
/declk\[/ {
	declk = 1
	next
}
/declk/ {
	next
}

/pckbd/ {
	gsub("pckbd", "ukbd", $0)
	mapname = $4
}

/KC/ {
	if (ignore)
		next

	if (declk)
		next

	haskeys = 1

	sidx = substr($1, 4, length($1) - 5)
	orig = int(sidx)
	id = conv[orig]

	# 183 is another Print Screen...
	if (orig == 183)
		next

	if (id == -1) {
		printf("/* initially KC(%d),", orig)
		for (f = 2; f <= NF; f++) {
			if ($f != "/*" && $f != "*/")
				printf("\t%s", $f)
		}
		printf("\t*/\n")
	} else {
		lines[id] = sprintf("    KC(%d),\t", id)
		#
		# This makes sure that the non-comment part of the output
		# ends up with a trailing comma. This is necessary since
		# the last line of an input block might not have a trailing
		# comma, but might not be the last line of an output block
		# due to sorting.
		#
		comma = 0
		for (f = 2; f <= NF; f++) {
			l = length($f)
			if ($f == "/*")
				comma++
			if (comma == 0 && substr($f, l) != ",") {
				lines[id] = sprintf("%s%s,", lines[id], $f)
				l++
			} else {
				lines[id] = sprintf("%s%s", lines[id], $f)
			}
			if (comma == 0 && f != NF) {
				if (l < 2 * 8)
					lines[id] = lines[id] "\t"
				if (l < 8)
					lines[id] = lines[id] "\t"
			}
			if ($f == "*/")
				comma--
		}
	}

	next
}
/};/ {
	if (ignore)
		next

	if (declk) {
		declk = 0
		next
	}

	if (haskeys) {
		# Duplicate 42 (backspace) as 76 and 50 (backslash bar) as 49
		if (!lines[76]) {
			lines[76] = lines[42]
			sub("42", "76", lines[76])
		}
		if (!lines[49]) {
			lines[49] = lines[50]
			sub("50", "49", lines[49])
		}

		#
		# Sun USB keyboards extra keys do not appear in the PS/2
		# maps. We add them here, except for the Compose key (101)
		# which conflicts with the ``menu'' key.
		#
		if (nmaps++ == 0) {
			# 102 Suspend
			lines[116] = "    KC(116),\tKS_Open,"
			lines[117] = "    KC(117),\tKS_Help,"
			lines[118] = "    KC(118),\tKS_Props,"
			lines[119] = "    KC(119),\tKS_Front,"
			lines[120] = "    KC(120),\tKS_Cmd,"
			lines[121] = "    KC(121),\tKS_Again,"
			lines[122] = "    KC(122),\tKS_Undo,"
			lines[123] = "    KC(123),\tKS_Cut,"
			lines[124] = "    KC(124),\tKS_Copy,"
			lines[125] = "    KC(125),\tKS_Paste,"
			lines[126] = "    KC(126),\tKS_Find,"
			lines[127] = "    KC(127),\tKS_AudioMute,"
			lines[128] = "    KC(128),\tKS_AudioRaise,"
			lines[129] = "    KC(129),\tKS_AudioLower,"
		}

		for (i = 0; i < 256; i++)
			if (lines[i]) {
				print lines[i]
				lines[i] = ""
			}

		haskeys = 0

		#
		# Apple black USB keyboards use a slightly different
		# layout. We define them here.
		#
		if (mapname == "ukbd_keydesc_fr[]") {
			print $0
			print "\nstatic const keysym_t ukbd_keydesc_fr_apple[] = {"
			print "    KC(5),\tKS_b,\t\tKS_B,\t\tKS_ssharp,"
			print "    KC(8),\tKS_e,\t\tKS_E,\t\tKS_ecircumflex,\tKS_Ecircumflex,"
			print "    KC(11),\tKS_h,\t\tKS_H,\t\tKS_Igrave,\tKS_Icircumflex,"
			print "    KC(12),\tKS_i,\t\tKS_I,\t\tKS_icircumflex,\tKS_idiaeresis,"
			print "    KC(13),\tKS_j,\t\tKS_J,\t\tKS_Idiaeresis,\tKS_Iacute,"
			print "    KC(14),\tKS_k,\t\tKS_K,\t\tKS_Egrave,\tKS_Ediaeresis,"
			print "    KC(15),\tKS_l,\t\tKS_L,\t\tKS_voidSymbol,\tKS_bar,"
			print "    KC(16),\tKS_comma,\tKS_question,\tKS_voidSymbol,\tKS_questiondown,"
			print "    KC(17),\tKS_n,\t\tKS_N,\t\tKS_asciitilde,"
			print "    KC(20),\tKS_a,\t\tKS_A,\t\tKS_ae,\t\tKS_AE,"
			print "    KC(21),\tKS_r,\t\tKS_R,\t\tKS_registered,\tKS_comma,"
			print "    KC(22),\tKS_s,\t\tKS_S,\t\tKS_Ograve,"
			print "    KC(26),\tKS_z,\t\tKS_Z,\t\tKS_Acircumflex,\tKS_Aring,"
			print "    KC(28),\tKS_y,\t\tKS_Y,\t\tKS_Uacute,"
			print "    KC(31),\tKS_eacute,\tKS_2,\t\tKS_ediaeresis,"
			print "    KC(32),\tKS_quotedbl,\tKS_3,"
			print "    KC(33),\tKS_apostrophe,\tKS_4,"
			print "    KC(34),\tKS_parenleft,\tKS_5,\t\tKS_braceleft,\tKS_bracketleft,"
			print "    KC(35),\tKS_section,\tKS_6,"
			print "    KC(36),\tKS_egrave,\tKS_7,\t\tKS_guillemotleft,"
			print "\t\t\t\t\t\tKS_guillemotright,"
			print "    KC(37),\tKS_exclam,\tKS_8,"
			print "    KC(38),\tKS_ccedilla,\tKS_9,\t\tKS_Ccedilla,\tKS_Aacute,"
			print "    KC(37),\tKS_exclam,\tKS_8,\t\tKS_exclamdown,\tKS_Ucircumflex,"
			print "    KC(39),\tKS_agrave,\tKS_0,\t\tKS_oslash,\tKS_Ooblique,"
			print "    KC(45),\tKS_parenright,\tKS_degree,\tKS_braceright,\tKS_bracketright,"
			print "    KC(46),\tKS_minus,\tKS_underscore,"
			print "    KC(47),\tKS_dead_circumflex, KS_dead_diaeresis,"
			print "\t\t\t\t\t\tKS_ocircumflex,\tKS_Ocircumflex,"
			print "    KC(48),\tKS_dollar,\tKS_asterisk,\tKS_cent,\tKS_yen,"
			print "    KC(50),\tKS_grave,\tKS_sterling,\tKS_at,\t\tKS_numbersign,"
			print "    KC(51),\tKS_m,\t\tKS_M,\t\tKS_mu,\t\tKS_Oacute,"
			print "    KC(52),\tKS_ugrave,\tKS_percent,\tKS_Ugrave,"
			print "    KC(53),\tKS_at,\t\tKS_numbersign,"
			print "    KC(55),\tKS_colon,\tKS_slash,\tKS_voidSymbol,\tKS_backslash,"
			print "    KC(56),\tKS_equal,\tKS_plus,"
			print "    KC(103),\tKS_KP_Equal,"
			print "    KC(231),\tKS_Mode_switch,\tKS_Multi_key,"
		} else
		if (mapname == "ukbd_keydesc_pt[]") {
			print $0
			print "\nstatic const keysym_t ukbd_keydesc_pt_apple[] = {"
			print "/*  pos\t\tnormal\t\tshifted */"
			print "    KC(46),\tKS_plus,\tKS_asterisk,"
			print "    KC(47),\tKS_masculine,\tKS_ordfeminine,"
			print "    KC(50),\tKS_backslash,\tKS_bar,"
			print "    KC(52),\tKS_dead_tilde,\tKS_dead_circumflex"
		}
	}
}
/KB_FR/ {
	print $0
	kbfr++
	# Add .apple variants, but not to the fr.dvorak variants
	if (kbfr == 1) {
		print "\tKBD_MAP(KB_FR | KB_APPLE,\tKB_FR,\tukbd_keydesc_fr_apple),"
	} else if (kbfr == 3) {
		print "\tKBD_MAP(KB_FR | KB_APPLE | KB_SWAPCTRLCAPS,\tKB_FR | KB_APPLE,"
		print "\t\tukbd_keydesc_swapctrlcaps),"
	}
	next
}
/KB_PT/ {
	print $0
	print "\tKBD_MAP(KB_PT | KB_APPLE,\tKB_PT,\tukbd_keydesc_pt_apple),"
	next
}
{
	if (ignore)
		next
	if (declk)
		next
	print $0
}
