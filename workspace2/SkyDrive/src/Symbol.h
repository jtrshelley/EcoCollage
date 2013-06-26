/*
 * Symbol.h
 *
 *  Created on: Jun 25, 2013
 *      Author: brianna
 */

#ifndef SYMBOL_H_
#define SYMBOL_H_
#include "opencv/cv.h"

namespace surf {

class Symbol {
public:
	Symbol(IplImage* img, int x, int y);
	virtual ~Symbol();
	IplImage* img;
	int x;
	int y;
};

} /* namespace surf */
#endif /* SYMBOL_H_ */
