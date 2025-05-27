// =============================================================================
// File        : nco.h
// Author      : @fjpolo
// email       : fjpolo@gmail.com
// Description : Numerically Controlled Oscillator (NCO) class.
// License     : MIT License
//
// Copyright (c) 2025 | @fjpolo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
#ifndef _nco_H_
#define _nco_H_

#include <math.h> // Required for sin() and M_PI

class NCO {
public:
    unsigned    m_lglen, m_len, m_mask, m_phase, m_dphase;
    float       *m_table;

    NCO(const int lgtblsize) {
        // We'll use a table 2^(lgtblize) in length. This is
        // non-negotiable, as the rest of this algorithm depends upon
        // this property.
        m_lglen = lgtblsize;
        m_len = (1 << lgtblsize);

        // m_mask is 1 for any bit used in the index, zero otherwise
        m_mask = m_len - 1;
        m_table = new float[m_len];

        // Corrected: Declare 'k' within the for loop scope
        for(int k = 0; k < m_len; k++) {
            m_table[k] = sin(2. * M_PI * k / (double)m_len);
        }

        // m_phase is the variable holding our PHI[n] function from
        // above.
        // We'll initialize our initial phase and frequency to zero
        m_phase = 0;
        m_dphase = 0;
    }

    // On any object deletion, make sure we delete the table as well
    ~NCO(void) {
        delete[] m_table;
    }

    // Adjust the sample rate for your implementation as necessary
    const float SAMPLE_RATE = 1.0;
    // ONE_ROTATION represents a full 360-degree rotation in the NCO's phase accumulator.
    // It's 2.0 multiplied by the maximum value an unsigned integer can hold,
    // effectively scaling the frequency input to the full range of the phase accumulator.
    const float ONE_ROTATION = 2.0 * (1u << (sizeof(unsigned) * 8 - 1));

    // Corrected: Changed return type to void as it sets internal state and doesn't need to return a float.
    void frequency(float f) {
        // Convert the frequency to a fractional difference in phase
        // This calculates the phase increment (m_dphase) required to achieve
        // the desired frequency 'f' given the SAMPLE_RATE.
        m_dphase = (unsigned int)(f * ONE_ROTATION / SAMPLE_RATE);
    }

    float operator ()(void) {
        unsigned index;

        // Increment the phase by an amount dictated by our frequency
        // m_phase was our PHI[n] value above
        m_phase += m_dphase; // PHI[n] = PHI[n-1] + (2^32 * f/fs)

        // Grab the top m_lglen bits of this phase word
        // Corrected: Added an extra pair of parentheses for correct operator precedence
        index = m_phase >> ((sizeof(unsigned) * 8) - m_lglen);

        // Insist that this index be found within 0... (m_len-1)
        index &= m_mask;

        // Finally return the table lookup value
        return m_table[index];
    }
}; // Corrected: Added missing semicolon after class definition

# endif // _nco_H_