//import SceneKit
//import UIKit
//
//class SceneExportDelegate: NSObject, SCNSceneExportDelegate {
//    func write(_ image: UIImage, withSceneDocumentURL documentURL: URL, originalImageURL: URL?) -> URL? {
//        // Spécifiez le répertoire où vous souhaitez enregistrer les images
//        let tempDirectory = FileManager.default.temporaryDirectory
//        let imageName = UUID().uuidString + ".png"
//        let imageURL = tempDirectory.appendingPathComponent(imageName)
//
//        // Enregistrez l'image en PNG
//        do {
//            if let imageData = image.pngData() {
//                try imageData.write(to: imageURL)
//                return imageURL
//            } else {
//                print("Erreur lors de la conversion de l'image en données PNG")
//                return nil
//            }
//        } catch {
//            print("Erreur lors de l'enregistrement de l'image : \(error)")
//            return nil
//        }
//    }
//}
