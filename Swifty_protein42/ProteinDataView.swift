import SwiftUI
import SceneKit

// Un wrapper Identifiable pour l'image
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ProteinDataView: View {
    var ligandId: String
    var pdbData: String
    @State private var scnView: SCNView?
    @State private var sceneIsReady = false

    @State private var shareURL: URL?
    @State private var identifiableImage: IdentifiableImage?

    @State private var showURLSheet = false
    // On utilise un item pour l'image, ce qui force SwiftUI à ne présenter la sheet que quand on a une image
    var body: some View {
        VStack {
            MoleculeSceneView(
                pdbData: pdbData,
                scnView: $scnView,
                sceneIsReady: $sceneIsReady
            )
            .edgesIgnoringSafeArea(.all)

            HStack {

                Button(action: {
                    print("Bouton partager image cliqué")
                    print("sceneIsReady: \(sceneIsReady)")
                    print("scnView is nil?: \(scnView == nil)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let image = generateSnapshot() {
                            print("Image capturée avec succès : \(image)")

                            identifiableImage = IdentifiableImage(image: image)
                        } else {
                            print("Erreur lors de la génération de l'image")
                        }
                    }
                }) {
                    Text("Share Image")
                        .padding()
                        .background(sceneIsReady ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!sceneIsReady)
            }
            .padding()
        }
        .navigationTitle("Ligand \(ligandId)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: sceneIsReady) { oldValue, newValue in
            print("sceneIsReady changed from \(oldValue) to \(newValue)")
        }
        // Sheet pour le fichier 3D
        .sheet(isPresented: $showURLSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            } else {
                Text("Aucun fichier à partager.")
            }
        }
        // Sheet pour l'image via .sheet(item:)
        .sheet(item: $identifiableImage) { identifiableImage in
            ShareSheet(activityItems: [identifiableImage.image])
        }
    }

    func saveSceneToFile() -> URL? {
        guard let scnView = scnView, let scene = scnView.scene else {
            print("Impossible de sauvegarder, scnView ou scene est nil")
            return nil
        }

        let fileName = "molecule.usdz"
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Impossible d'accéder au dossier documents")
            return nil
        }
        let fileURL = documentsURL.appendingPathComponent(fileName)

        let options = [SCNSceneExportDestinationURL: fileURL] as [String: Any]
        scene.write(to: fileURL, options: options, delegate: nil, progressHandler: nil)
        return fileURL
    }

    func generateSnapshot() -> UIImage? {
        guard let scnView = scnView else {
            print("scnView est nil, impossible de générer un snapshot")
            return nil
        }

        let bounds = scnView.bounds
        print("scnView bounds: \(bounds)")
        let image = scnView.snapshot()
        print("Image snapshot: \(String(describing: image))")
        return image
    }
}
