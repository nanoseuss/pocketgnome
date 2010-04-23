/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id$
 *
 */

// Return types for performAction
//	More errors here: http://www.wowwiki.com/WoW_Constants/Errors
typedef enum CastError {
    ErrNone = 0,
	ErrNotFound = 1,
    ErrInventoryFull = 2,				// @"Inventory is Full"
    ErrTargetNotInLOS = 3,
	ErrCantMove = 4,
	ErrTargetNotInFrnt = 5,	
	ErrWrng_Way = 6,
	ErrSpell_Cooldown  = 7,
	ErrAttack_Stunned  = 8,
	ErrSpellNot_Ready  = 9,
	ErrTargetOutRange  = 10,
	//ErrTargetOutRange2  = 11,
	//ErrSpellNot_Ready2  = 12,
	ErrSpellNotReady = 13,
	ErrInvalidTarget = 14,
	ErrTargetDead = 15,
	ErrCantAttackMounted = 16,
	ErrYouAreMounted = 17,
} CastError;

#define INV_FULL			@"Inventory is full."
#define TARGET_LOS			@"Target not in line of sight"
#define SPELL_NOT_READY		@"Spell is not ready yet."
#define CANT_MOVE			@"Can't do that while moving"
#define TARGET_FRNT			@"Target needs to be in front of you."
#define WRNG_WAY			@"You are facing the wrong way!"
#define NOT_YET			    @"You can't do that yet"
#define SPELL_NOT_READY2    @"Spell is not ready yet."
#define NOT_RDY2			@"Ability is not ready yet."
#define ATTACK_STUNNED	    @"Can't attack while stunned."
#define TARGET_RNGE			@"Out of range."
#define TARGET_RNGE2		@"You are too far away!"
#define INVALID_TARGET		@"Invalid target"
#define TARGET_DEAD			@"Your target is dead"
#define CANT_ATTACK_MOUNTED	@"Can't attack while mounted."
#define YOU_ARE_MOUNTED		@"You are mounted."
#define CANT_ATTACK_TARGET	@"You cannot attack that target."


//Must have a Fishing Pole equipped
//Can't do that while silenced
//Can't do that while stunned
//Not enough mana
//Can't do that while incapacitated
//Not enough energy