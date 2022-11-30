//
//  SSDCreditCardOcr.swift
//  CardScan
//
//  Created by xaen on 5/15/20.
//
import UIKit

class SSDCreditCardOcr: CreditCardOcrImplementation {
    let ocr: OcrDD

    override init(
        dispatchQueueLabel: String
    ) {
        ocr = OcrDD()
        super.init(dispatchQueueLabel: dispatchQueueLabel)
    }

    override func recognizeCard(
        in fullImage: CGImage,
        roiRectangle: CGRect
    ) -> CreditCardOcrPrediction {

        guard
            let (image, ocrRoiRectangle) = fullImage.croppedImageForSsd(roiRectangle: roiRectangle)
        else {
            return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }

        let startTime = Date()

        guard let (string, isNumber) = ocr.perform(croppedCardImage: image) else {
            return CreditCardOcrPrediction.emptyPrediction(cgImage: fullImage)
        }

        let duration = -startTime.timeIntervalSinceNow
        let numberBoxes = ocr.lastDetectedBoxes

        self.computationTime += duration
        self.frames += 1
        return CreditCardOcrPrediction(
            image: image,
            ocrCroppingRectangle: ocrRoiRectangle,
            number: string,
            hasNumbers: isNumber,
            expiryMonth: nil,
            expiryYear: nil,
            name: nil,
            computationTime: duration,
            numberBoxes: numberBoxes,
            expiryBoxes: nil,
            nameBoxes: nil
        )
    }
}
