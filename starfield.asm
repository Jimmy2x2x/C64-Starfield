; [WELCOME] -------------------------------------------------------------------

; Starfield example code

; This code has been extracted from my 2017 Commodore 64 game 'Galencia'
; and this portion of the code is placed in the public domain 10 December 2017
; feel free to use this code for any purpose with the exception of reproducing
; this tutorial, in part or whole, in a magazine, diskmag, website or similar.
; If you want to do this, please email me and ask for permission prior to
; publication.

; I have spent a few hours making this code as easy to understand as I can
; with heavy comments and everything defined to be as portable as possible.

; If you find this code useful and would like to see more like this
; you can buy me a pint via the magic of paypal

; my paypal: jay.aldred@gmail.com

; Cheers, Jay


; [DESCRIPTION] ---------------------------------------------------------------

; The starfield revolves around plotting pixels into a custom character set

; It works by reprogramming 50 characters in the charset.

; The screen is 25 chars tall and I use two columns worth of characters
; (2 x 25 = 50 chars)

; I have allocated characters 58 to 107 to be the 50 star characters
; as this fit around my needs in Galencia

; This code was assembled using:
; CBM prg Studio by Arthur Jordison     http://www.ajordison.co.uk/


; [EQUATES] -------------------------------------------------------------------

starScreenChar  = $0400         ; Screen address
StarScreenCols  = $d800         ; Character attribute address

charBase        = $3000         ; Address of our character set

star1Init       = charBase+$1d0 ; Init address for each star
star2Init       = charBase+$298
star3Init       = charBase+$240
star4Init       = charBase+$2e0

star1Limit      = charBase+$298 ; Limit for each star
star2Limit      = charBase+$360 ; Once limit is reached, they are reset
star3Limit      = charBase+$298
star4Limit      = charBase+$360

star1Reset      = charBase+$1d0 ; Reset address for each star
star2Reset      = charBase+$298
star3Reset      = charBase+$1d0
star4Reset      = charBase+$298

staticStar1     = charBase+$250 ; 2 Locations for blinking static stars
staticStar2     = charBase+$1e0

starColourLimit = 20            ; use values 1 to 20
                                ; Galencia uses these values
                                ; 1     = mono
                                ; 2     = duo
                                ; 20    = full colour

; [ZERO PAGE VARIABLES] -------------------------------------------------------

starfieldPtr    = $f0           ; 4 x pointers for moving stars
starfieldPtr2   = $f2
starfieldPtr3   = $f4
starfieldPtr4   = $f6

zeroPointer     = $f8           ; General purpose pointer

rasterCount     = $fa           ; Counter that increments each frame


; [AUTO RUN] ------------------------------------------------------------------

; These byte values are a basic SYS call to autoexecute the code.

*=$0801

        BYTE    $0E,$08,$0A,$00,$9E,$20,$28,$32,$30,$36,$34,$29,$00,$00,$00

; [CODE START] ----------------------------------------------------------------

*=$0810

        sei                             ; Disable all IRQ

        lda #<charBase                  ; Clear charset data
        sta zeroPointer
        lda #>charBase
        sta zeroPointer+1
        ldx #8-1
        ldy #0
        tya
@clrChars
        sta (zeroPointer),y
        iny
        bne @clrChars
        inc zeroPointer+1
        dex
        bne @clrChars

        sta $d020                       ; Border and screen colour to 0 (black)
        sta $d021

        lda #28                         ; Characters at $3000
        sta $d018
                
        jsr initStarfield               ; Reset all pointers
        jsr createStarScreen            ; Initialise Starfield
@loop

        lda #$ff                        ; Wait for raster to be off screen
@wait
        cmp $d012
        bne @wait
        
        inc rasterCount                 ; Increment our 8 bit counter

        dec $d020                       ; Change border colour to show
                                        ; how long routine is taking to
                                        ; execute

        jsr doStarfield                 ; erase, move and redraw the stars

        inc $d020                       ; restore border colour

        jmp @loop                       ; Loop around for another pass


; [Do Starfield] --------------------------------------------------------------

; This routine does 3 things:

; 1) Erases stars
; 2) Moves stars
; 3) Draws stars in new position


doStarfield

; Erase stars

        lda #0                                  ; Erase 4 stars
        tay
        sta (starfieldPtr),y
        sta (starfieldPtr2),y
        sta (starfieldPtr3),y
        sta (starfieldPtr4),y

; Move star 1

        lda rasterCount                         ; Test bit 0 of counter
        and #1                                  ; move 1 pixel every
        beq @star1Done                          ; other frame, to simulate
        inc starfieldPtr                        ; 1/2 pixel movement
        bne @ok
        inc starfieldPtr+1
@ok
        lda starfieldPtr
        cmp #<star1Limit
        bne @star1Done
        lda starfieldPtr+1
        cmp #>star1Limit
        bne @star1Done
        lda #<star1Reset                        ; Reset 1
        sta starfieldPtr
        lda #>star1Reset
        sta starfieldPtr+1
@star1Done

; Move star 2

        inc starfieldPtr2                       ; 1 pixel per frame
        bne @ok2                                
        inc starfieldPtr2+1
@ok2
        lda starfieldPtr2
        cmp #<star2Limit
        bne @star2Done
        lda starfieldPtr2+1
        cmp #>star2Limit
        bne @star2Done
        lda #<star2Reset                        ; Reset 2
        sta starfieldPtr2
        lda #>star2Reset
        sta starfieldPtr2+1
@star2Done

; Move star 3

        lda rasterCount                         ; half pixel per frame
        and #1
        beq @star3done
        inc starfieldPtr3
        bne @ok3
        inc starfieldPtr3+1
@ok3
        lda starfieldPtr3
        cmp #<star3Limit
        bne @star3done
        lda starfieldPtr3+1
        cmp #>star3Limit
        bne @star3done
        lda #<star3Reset                        ; Reset 3
        sta starfieldPtr3
        lda #>star3Reset
        sta starfieldPtr3+1
@star3done

; Move star 4

        lda starfieldPtr4                       ; 2 pixels per frame
        clc
        adc #2
        sta starfieldPtr4
        bcc @ok4
        inc starfieldPtr4+1
@ok4
        lda starfieldPtr4+1
        cmp #>star4Limit
        bne @star4done
        lda starfieldPtr4
        cmp #<star4Limit
        bcc @star4done
        lda #<star4Reset                       ; Reset 4
        sta starfieldPtr4
        lda #>star4Reset
        sta starfieldPtr4+1
@star4done

 ; 2 static stars that flicker

        lda #192                       
        ldy rasterCount
        cpy #230
        bcc @show
        lda #0
@show   sta staticStar1 

        tya
        eor #$80
        tay
        lda #192
        cpy #230
        bcc @show2
        lda #0
@show2  sta staticStar2

; Plot new stars
                
        ldy #0
        lda (starfieldPtr),y            ; Moving stars dont overlap other stars
        ora #3                          ; as they use non conflicting bit
        sta (starfieldPtr),y            ; combinations

        lda (starfieldPtr2),y
        ora #3
        sta (starfieldPtr2),y

        lda (starfieldPtr3),y
        ora #12
        sta (starfieldPtr3),y

        lda (starfieldPtr4),y
        ora #48
        sta (starfieldPtr4),y

        rts


; [Initialise Starfield Pointers] ---------------------------------------------

; Initialise all pointers, note these INIT values maybe different to RESET
; values, this is give a non-uniform appearance to the stars and reduce
; obvious 'patterning' - I tried to give a fairly natural appearance.

initStarfield
        lda #<star1Init 
        sta starfieldPtr
        lda #>star1Init
        sta starfieldPtr+1

        lda #<star2Init 
        sta starfieldPtr2
        lda #>star2Init
        sta starfieldPtr2+1

        lda #<star3Init 
        sta starfieldPtr3
        lda #>star3Init
        sta starfieldPtr3+1

        lda #<star4Init  
        sta starfieldPtr4
        lda #>star4Init
        sta starfieldPtr4+1

        rts


; [Create Star Screen] --------------------------------------------------------

; Creates the starfield charmap and colour charmap

; This routine paints vertical stripes of colour into the colourmap
; so the stars are different colours

; It also plots the correct characters to the screen, wrapping them around
; at the correct char count to give to the starfield effect.


CreateStarScreen
        ldx #40-1                       ; Create starfield of chars
@lp     txa
        pha
        tay
        lda StarfieldRow,x

        sta @smc1+1
        ldx #58+25
        cmp #58+25
        bcc @low
        ldx #58+50
@low    stx @smc3+1
        txa
        sec
        sbc #25
        sta @smc2+1
        lda #<starScreenChar
        sta zeroPointer
        lda #>starScreenChar
        sta zeroPointer+1 
        ldx #25-1
@smc1   lda #3
        sta (zeropointer),y
        lda zeropointer
        clc
        adc #40
        sta zeropointer
        bcc @clr
        inc zeropointer+1
@clr    inc @smc1+1
        lda @smc1+1
@smc3   cmp #0
        bne @onscreen
@smc2   lda #0
        sta @smc1+1
@onscreen        
        dex
        bpl @smc1

        pla
        tax
        dex
        bpl @lp

        lda #<StarScreenCols           ; Fill colour map with vertical stripes of colour for starfield
        sta zeroPointer
        lda #>StarScreenCols
        sta zeroPointer+1
        ldx #25-1
@lp1    stx @smcx+1
        ldx #0
        ldy #40-1
@lp2
        lda starfieldCols,x
        sta (zeroPointer),y
        inx
        cpx #StarColourLimit
        bne @col
        ldx #0
@col
        dey
        bpl @lp2
        lda zeroPointer
        clc
        adc #40
        sta zeroPointer
        bcc @hiOk
        inc zeroPointer+1
@hiOk
@smcx
        ldx #0
        dex
        bpl @lp1
        rts


; [DATA] ----------------------------------------------------------------------

; Dark starfield so it doesnt distract from bullets and text
starfieldCols

        byte 14,10,12,15,14,13,12,11,10,14
        byte 14,10,14,15,14,13,12,11,10,12

; Star positions, 40 X positions, range 58-107
starfieldRow
        byte 058,092,073,064,091,062,093,081,066,094
        byte 086,059,079,087,080,071,076,067,082,095
        byte 100,078,099,060,075,063,084,065,083,096
        byte 068,088,074,061,090,098,085,101,097,077



