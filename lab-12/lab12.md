# Lab 12: I2C, Reading Datasheets (Non-mandatory, counts as extra credit)

## NOTE: Finished, but not what I wanted it to be.
I can't tell if I'm having issues with my micro, my MCP is broken, or if I'm just dumb? Either way, this lab was intended to make you scan the keypad with the MCP chip. Instead, you'll be turning on an LED. To make up for the lost content, I'm not inserting in a wiring schematic. This should be pretty easy to figure out.

You should read [this](https://piazza.com/class/lcmb4r2lt4z4w7/post/537) Piazza post if you haven't already.

## 1: Introduction
The STM32 is capable of several different protocols, making it a relatively versatile tool in the world of embedded system design. However, other off-the-shelf microcontrollers may not quite have everything the STM32 series does, such as the ATMEL chips that Arduinos are based off of. One peripheral communication protocol seems to persist is most controllers, even the cheaper ones, and that's I2C.

## 2: Instructional Objectives
- To learn the general principles of I2C interfacing.
- To understand how to use the STM32's I2C peripheral to interface with external devices.

## 3: Background
I2C is a prevalent protocol for a few different reasons:
- Ability to address different devices on one singular line (typically up to 255).
- Significantly less parts to embed onto a PCB.
- Two points-of-failure instead of four.

I2C communication protocol is generally used for creating large busses that include more than a singular device. All connected devices communicate on the same set of wires, of which there are two:
- SCL (clock)
- SDA (data)

Further, every device uses an open-drain interface, meaning that each device can only pull down. Consequently, both of the lines must be pulled up with a strong pull-up resistor, meaning stronger than what the STM32 (and most other chips available) has internally. In general, there is actually a very careful set of mathematical measurements and calculations involved with designing a proper I2C bus. You may remember from 2k1 that RC circuits have a charge constant associated with how quickly the circuit rises and falls. In general, for every circuit out there, there's a resistive, capacitive, and inductive component out there, although the resistive and capacitive components are incredibly small, and the inductive component is usually even smaller! For general use, you can reuse the formula:

$$ V_{C} = V_{1}(1-e^{\frac{-t}{\tau}})$$

 - and -

$$ \tau = RC $$


In the past, we used to make you calculate the rise and fall times that would be appropriate for the circuit you'll be building. Since this lab is taking place during dead week, we won't be making you do that. 

### 3.1: Basic Protocol
I2C peripheral devices operate with streams of writes and reads. The initial byte identifies the device that the stream is intended to interact with (its 7-bit identifier) as well as one bit to indicate if the stream is being written to or read from the device.

### 3.2: MCP23008 (GPIO Extender) I2C Protocol
The MCP23008 contains eleven internal registers, each of which has an address. To write one of these registers, a stream of bytes is written to the I2C channel like so:
  
        Start
        {7-bit device ID} Wr Ack        1st byte
        {Register address} Ack          2nd byte
        {New register contents} Ack     3rd byte
        Stop
        
To read from a register, the address of the particular register must first be written with a write stream. Thereafter, a read stream will deliver the contents of the selected register to the initiating master device like so:

        Start
        {7-bit device ID} Wr Ack        1st byte
        {Register address} Ack          2nd byte
        Stop (optional)
        Start
        {7-bit device ID} Rd Ack        1st byte
        {Register contents} Ack         2nd byte
        Stop
> **NOTE:** It is possible to fuse the two streams together by, instead of issuing a protocol Stop at the end of the write stream, issuing a second Start followed by the read stream. We won't necessarily do that for this lab experiment. (You are welcome to implement your subroutines in this way if you want to.)

Figure 1-1 on page 7 of the MCP23008 data sheet graphically illustrates the different I2C operations. In this figure, the OP refers to the opcode which is the 7-bit I2C address. The ADDR represents the register address in the selected I2C device. (In this way, they avoid confusion between the device address and register address.)

The MCP23008 is structurally similar to the GPIO ports of the STM32. One register (IODIR) controls the direction of the pins (inputs or outputs). The IODIR is an 8-bit register where each bit represents the direction of each corresponding GPx pin. To set a pin for output, write a '0' to its IODIR entry. To configure a pin as an input (the default) write a '1' to its IODIR entry. Another register (GPIO) is used to write values to and read values from the pins.

>**NOTE:** There is a hidden register in the MCP23008 that keeps track of the register address. Every I2C byte written to a register or read from a register causes this hidden register to be incremented. In this way, one could write to all eleven registers by selecting register address 0 followed by 11 data values. The selected register would be advanced for each successive data value.

### 3.4: I2C Registers and Useful Bits
- `CR1:` First generic control register. There's a ton of stuff in here, and we're only going to use a small amount:
-     `PE:` Peripheral enable. Enables and disables the peripheral.
-     `ANFOFF:` A filter that tried to reduce EMF noise.
-     `NOSTRETCH:` Doesn't allow the clock speed to change.
-     `ERRIE:` An interrupt for if an error is detected.
- `TIMINGR:` A register for all things related to timing.
-     `PRESC:` You should be able to figure out what this does by now.
-     `SCLDEL:` Data setup time. How many cycles are allowed for a rise.
-     `SDADEL:` Clcok setup time. Generates a delay between SCL and SDA.
-     `SCLH:` How long the SCL is high for.
-     `SCLL:` How long the SCL is low for.
- `OAR1` and `OAR2:` Fields to set addresses for the STM32FO01, in case it's being used as a slave.
- `CR2:` Second generic control register. Similar to the above, we will use a small amount of what's in here:
-     `ADD10:` Flips between 7-bit and 10-bit addressing mode.
-     `AUTOEND:` As it sounds, it automatically ends a transaction. 

### 3.5: Wiring the MCP23008
[here](https://ww1.microchip.com/downloads/en/DeviceDoc/MCP23008-MCP23S08-Data-Sheet-20001919F.pdf) is a link to the datasheet for this chip. You should:
- Connect VDD to 3V.
- Connect VSS to GND.
- Connect A0, A1, A2 to GND.
- Connect PB6 to SCL.
- Connect PB7 to SDA
- Connect a weak pull-up resistor between 3V and PB6. (Something between 1.2k to 2.8k.)
- Connect a weak pull-up resistor between 3V and PB7. (Something between 1.2k to 2.8k.)
- Connect (not) reset to 3V.
- Don't connect `INT` or the `NC` pin. 
- Connect an LED (with a 150-ohm current limiting resistor, as usual) to one of the GPIO pins. Any one will work.

## 5: Helper Functions
**First, build a blank project like we did in lab 5.0. We won't be providing a template this time around.**

We didn't get around to showing this sort of code structure this semester. When you go on to do personal projects, senior design, and/or industry work, it's *sometimes* good to structure your code in a way that abstracts the hardware out for general use. This methodology is called a Hardware Abstraction Layer, and most of the time they're garbage.

The problem with HALs is they're usually written with a specific purpose in mind (carrying data from one specific type of peripheral to/from the micro is a good example), and they use data structures and functions that are tailored to that purpose. Most of the time, it feels like interns write these because the actual engineers are busy doing something else. TI's MSP and STM's HALs are ones that I tend to encounter in the wild a lot, and they're almost completely useless, especially since you can't see the source code, so you don't know what's going on.

Here, I am providing most of a HAl for your I2C. Look carefully at what's happening. All of this is similar to things that you've done in class, just instead of writing it yourself, a lot of it is prewritten. Some of it is not, and you must fill in a couple of marked-out gaps in this code. When you're done with this, these functions are useable and you don't have to mess with the code on the low-level side. Create a file in the `src` folder named `i2c.c.` Copy these functions into there. 
<!---
```C
void i2c_start(uint32_t targadr, uint8_t size, uint8_t dir)
{
  // Initialize I2C1 to 400 kHz
  void i2c_init(void) {
  RCC->AHBENR |= RCC_AHBENR_GPIOBEN;
  GPIOB->MODER |= 2<<(2*6) | 2<<(2*7);
  GPIOB->AFR[0] |= 1<<(4*6) | 1<<(4*7);
  RCC->APB1ENR |= RCC_APB1ENR_I2C1EN;
  //RCC->CFGR3 |= RCC_CFGR3_I2C1SW; // to set for 48MHz sysclk
  // default is 8MHz "HSI" clk
  
  // I2C CR1 Config
  I2C1->CR1 &= ~I2C_CR1_PE; // Disable to perform reset.
  I2C1->CR1 &= ~I2C_CR1_ANFOFF; // 0: Analog noise filter on.
  I2C1->CR1 &= ~I2C_CR1_ERRIE; // Error interrupt disable
  I2C1->CR1 &= ~I2C_CR1_NOSTRETCH; // Enable clock stretching
  
  // From table 83. p642 of FRM. Set for 400 kHz with 8MHz clock.
  I2C1->TIMINGR = 0;
  I2C1->TIMINGR &= ~I2C_TIMINGR_PRESC;// Clear prescaler
  I2C1->TIMINGR |= 0 << 28; // Set prescaler to 0
  I2C1->TIMINGR |= 3 << 20; // SCLDEL
  I2C1->TIMINGR |= 1 << 16; // SDADEL
  I2C1->TIMINGR |= 3 << 8; // SCLH
  I2C1->TIMINGR |= 9 << 0; // SCLL
  
  // I2C "Own address" 1 register (I2C_OAR1)
  I2C1->OAR1 &= ~I2C_OAR1_OA1EN; // Disable own address 1
  I2C1->OAR1 = I2C_OAR1_OA1EN | 0x2;// Set 7-bit own address 1
  I2C1->OAR2 &= ~I2C_OAR2_OA2EN; // Disable own address 2
  I2C1->CR2 &= ~I2C_CR2_ADD10; // 0 = 7-bit mode; 1 = 10-bit
  I2C1->CR2 |= I2C_CR2_AUTOEND; // Enable the auto end
  I2C1->CR2 |= I2C_CR2_NACK; // For slave mode: set NACK
  I2C1->CR1 |= I2C_CR1_PE; // Enable I2C1
}
```
-->
```C
// dir: 0 = master requests a write transfer
  // dir: 1 = master requests a read transfer

  // Take current contents. Remove items that may not be applicable.
  // ---------------------- THERE ARE EXTRA ITEMS HERE THAT YOU DON't NEED.----------------------------------------------------
  // -----------------------------------------REMOVE THEM.---------------------------------------------------------------------
  uint32_t tmpreg = I2C1->CR2;
  tmpreg &= ~(I2C_CR2_SADD | I2C_CR2_NBYTES | I2C_CR2_RD_WRN | I2C_CR2_START | I2C_CR2_STOP);
  // ----------------------------------------END PROBLEM-----------------------------------------------------------------------

  // Set read/write direction.
  if (dir == 1) tmpreg |= I2C_CR2_RD_WRN; // Read from slave
  else tmpreg &= ~I2C_CR2_RD_WRN; // Write to slave

  // Set the target's address and the data size.
  tmpreg |= ((targadr<<1) & I2C_CR2_SADD) | ((size << 16) & I2C_CR2_NBYTES);
  tmpreg |= I2C_CR2_START;

  // Start conversion.
  I2C1->CR2 = tmpreg;
}
```

```C
void i2c_stop(void) 
{
// If transaction has already been stopped, break from function if so.
  if (I2C1->ISR & I2C_ISR_STOPF) return;

  // Master: Generate STOP bit after current byte has been transferred.
  I2C1->CR2 |= I2C_CR2_STOP;

  // Wait until STOPF flag is reset
  while(!(I2C1->ISR & I2C_ISR_STOPF));

  I2C1->ICR |= I2C_ICR_STOPCF; // Write to clear STOPF flag
}
```

```C
void i2c_waitidle(void) 
{
  while ((I2C1->ISR & I2C_ISR_BUSY) == I2C_ISR_BUSY); // while busy, wait.
}
```

```C
int8_t i2c_senddata(uint8_t targadr, uint8_t data[], uint8_t size)
{
  int i;
  //if (size <= 0 || data == 0) return -1;

  uint8_t *udata = (uint8_t*)data;

  i2c_waitidle();

  i2c_start(targadr, size, 0);
  for(i=0; i<size; i++)
  {
    // TXIS bit is set by hardware when the TXDR register is empty and the
    // data to be transmitted must be written in the TXDR register. It is
    // cleared when the next data to be sent is written in the TXDR reg

    // The TXIS flag is not set when a NACK is received.
    //int count = 0;

    // This stanza breaks from the function if nothing responds.
    while(!(I2C1->ISR & I2C_ISR_TXE));
//    { 
//      count += 1;
//      if (count > 1000000) return -1;
//      if (i2c_checknack())              // I took this part out.
//      {
//        i2c_clearnack();
//        i2c_stop();
//        return -1;
//      }
//
//   // TXIS is then cleared by writing to the TXDR register.
//    }
    I2C1->TXDR = udata[i];
    //I2C1->TXDR = ((udata>>(8*(i-1))) & I2C_TXDR_TXDATA);
  }

  // Wait until TC flag is set or the NACK flag is set.
  //while(!(I2C1->ISR & I2C_ISR_TC)); //== 0 && (I2C1->ISR & I2C_ISR_NACKF) == 0);
  if ((I2C1->ISR & I2C_ISR_NACKF) != 0) return -1;

  i2c_stop();

  return 0;
}
```

```C
int i2c_recvdata(uint8_t targadr, void *data, uint8_t size) {
int i; // Counter for later for loop.

  if (size <= 0 || data == 0) return -1;

  uint8_t *udata = (uint8_t*)data;
  i2c_waitidle();

  // Last argument is dir: 1 = receiving data from the slave device.
  i2c_start(targadr, size, 1);
  for(i=0; i<size; i++)
  {
    int count = 0;
    while( (I2C1->ISR & I2C_ISR_RXNE) == 0)
    {
      count += 1;
      if (count > 1000000) return -1;
      if (i2c_checknack()) // If NACK, stop conversion and break from function.
      {
        i2c_clearnack();
        i2c_stop();
        return -1;
      }
    }
    udata[i] = I2C1->RXDR;
  }

  // Wait until TC flag is set or the NACK flag is set.
  while((I2C1->ISR & I2C_ISR_TC) == 0 && (I2C1->ISR & I2C_ISR_NACKF) == 0);

  // If NACK, break from function.
  if ( (I2C1->ISR & I2C_ISR_NACKF) != 0) return -1;

  i2c_stop();
  return 0;
}
```

```C
void i2c_clearnack(void)
{
  // This is simple, just clear the NACK flag in the ISR.
}

```C
int i2c_checknack(void)
{
  // This is simple. Just check if NACK flag is set in the ISR. Return a 1 if so.
}
```

### 5.1: `i2c_setup()` (20 Points)
Write a C subroutine named `init_i2c()` in `i2c.c` that:
- Enables `GPIOB.`
- PB6 to SCL. 
- PB7 to SDA.
- Enables `I2C1`

Once this is done, implement the following setup code for the I2C1 bus:
- Disable `PE` in `CR1.`
- Disable `ANFOFF` in `CR1.`
- Disable `ERRIE` in `CR1.`
- Disable `NOSTRETCH` in `CR1.`
- Set `PRESC` to 0 in `TIMINGR.`
- Set `SCLDEL` to 3 in `TIMINGR.`
- Set `SDADEL` to 1 in `TIMINGR.`
- Set `SCLH` to 3 in `TIMINGR.`
- Set `SCLL` to 9 in `TIMINGR.`
- Disable the "own address" feature in `OAR1.`
- Disable the "own address" feature in `OAR2.`
- Configure `ADD10` in `CR2` for 7-bit mode.
- Enable `AUTOEND` in `CR2.`
- Enable `PE.`

### 5.2: Include `i2c.h`

As it sounds, `include "i2c.h"` into your `i2c.c' file. It'll throw an error until you create i2c.h. This is fine.

**Checkoff:** TA's, just make sure they have this subroutine completed correctly, and everything is dropped into the i2c.c and i2c.h folders.

### 5.2: Creating a .h File
Create a file in the `inc` folder with the name `i2c.h.` Use the structure near the bottom of `lcd.h` from lab 10 as a guide. You must:
- Declare all of the functions in `i2c.c` 
- Include `lcd.h' in your `main.c` file.

## 6: Using the I2C
Now that your file structures are included into your `main.c` file, you should be able to call them from it. Try calling `i2c_init()` in main, building it, and seeing if it throws any errors. If it does, check back and make sure you defined all of your functions properly in `i2c.h` and included the correct files in `i2c.c` and `main.c.`

### 6.1: Turn on the GPIO port.
**Before you do anything, paste in the updated code if you made your .h file before Sunday.**

Write an initialization script that turns on the GPIO port in the MCP23008 and sets it to an output. Normally how  is:

```C 

// Replace the for(;;) loop in main with this.
uint8_t data1[0x00, config_byte] // Register address is 0x00. See page 8 on the datasheet for what you should set it to.
uint8_t data2[0x09, output_byte] // "ODR" address is 0x09. See page 19 for what you should set it to.

i2c_setup();
i2c_waitidle();
i2c_senddata(0x20, data1, 2); // General call for a whole transation.
i2c_senddata(0x20, data2, 2); // 0x20 is chip address, datax is transaction
                              // final number is number of bytes sent.
```
Doing this *should* turn that LED on, but for me it doesn't seem to work. I have to offset the memory addresses by a byte. There's more sophisticated ways you can go about this, but it doesn't matter to me for a code this short. If you're not able to get your output to work, try this:

```C
// Replace the for(;;) loop in main with this.
uint8_t data0[0x00, 0x00];
uint8_t data1[config_byte, 0x09]; 
uint8_t data2[output_byte, 0x00]; 

i2c_setup();
i2c_waitidle();
i2c_senddata[0x20, data0, 2);
i2c_senddata(0x20, data1, 2); 
i2c_senddata(0x20, data2, 2); 
                              
```

### 6.2: Demo

Show your TA the lightbulb turning on. If it turns on, you're done!
