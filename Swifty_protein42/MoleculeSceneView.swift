import SwiftUI
import SceneKit

struct MoleculeSceneView: UIViewRepresentable {
    var pdbData: String

    @Binding var scnView: SCNView?
    @Binding var sceneIsReady: Bool

    func makeUIView(context: Context) -> SCNView {
        print("[MoleculeSceneView] makeUIView appelé")
        let scnView = SCNView()
        let scene = createScene()
        print("[MoleculeSceneView] Scene créée, nombre de noeuds root: \(scene.rootNode.childNodes.count)")
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.systemBackground

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scnView.addGestureRecognizer(tapGesture)

        // Ajout du zoom (pinch)
        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        scnView.addGestureRecognizer(pinchGesture)

        context.coordinator.scnView = scnView
        scnView.delegate = context.coordinator

        DispatchQueue.main.async {
            self.scnView = scnView
            print("[MoleculeSceneView] scnView assigné. bounds: \(scnView.bounds)")
        }

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Pas de mise à jour nécessaire
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func createScene() -> SCNScene {
        print("[MoleculeSceneView] createScene appelé")
        let scene = SCNScene()

        let (atoms, bonds) = parsePDBData(pdbData)
        print("[MoleculeSceneView] Nombre d'atomes: \(atoms.count), Nombre de liaisons: \(bonds.count)")

        // Ajouter les atomes à la scène
        for atom in atoms {
            let sphere = SCNSphere(radius: atomRadius(for: atom.element))
            sphere.firstMaterial?.diffuse.contents = cpkColor(for: atom.element)

            let node = SCNNode(geometry: sphere)
            node.position = atom.position
            node.name = atom.element
            scene.rootNode.addChildNode(node)
        }

        // Ajouter les liaisons à la scène
        for bond in bonds {
            if let atom1 = atoms.first(where: { $0.serialNumber == bond.atom1Serial }),
               let atom2 = atoms.first(where: { $0.serialNumber == bond.atom2Serial }) {
                let cylinderNode = bondNode(from: atom1.position, to: atom2.position)
                scene.rootNode.addChildNode(cylinderNode)
            }
        }

        return scene
    }

    func bondNode(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let vector = SCNVector3(to.x - from.x, to.y - from.y, to.z - from.z)
        let distance = CGFloat(sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z))

        let cylinder = SCNCylinder(radius: 0.1, height: distance)
        cylinder.firstMaterial?.diffuse.contents = UIColor.gray

        let node = SCNNode(geometry: cylinder)
        node.position = SCNVector3((from.x + to.x) / 2, (from.y + to.y) / 2, (from.z + to.z) / 2)
        node.look(at: to, up: node.worldUp, localFront: node.worldUp)

        return node
    }

    func cpkColor(for element: String) -> UIColor {
        switch element.uppercased() {
        case "H": return UIColor.white
        case "C": return UIColor.black
        case "N": return UIColor.blue
        case "O": return UIColor.red
        case "F", "CL": return UIColor.green
        case "BR": return UIColor.brown
        case "I": return UIColor.purple
        case "HE", "NE", "AR", "XE", "KR": return UIColor.cyan
        case "P": return UIColor.orange
        case "S": return UIColor.yellow
        case "B": return UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
        case "LI", "NA", "K": return UIColor.purple
        case "CA": return UIColor.gray
        case "FE": return UIColor.orange
        case "ZN": return UIColor(red: 0.49, green: 0.5, blue: 0.69, alpha: 1.0)
        default: return UIColor.lightGray
        }
    }

    func atomRadius(for element: String) -> CGFloat {
        switch element.uppercased() {
        case "H": return 0.2
        case "C": return 0.3
        case "N": return 0.3
        case "O": return 0.3
        default: return 0.3
        }
    }

    func parsePDBData(_ pdbData: String) -> ([Atom], [Bond]) {
        var atoms: [Atom] = []
        var bonds: [Bond] = []

        let lines = pdbData.components(separatedBy: .newlines)

        for line in lines {
            if line.starts(with: "ATOM") || line.starts(with: "HETATM") {
                let serialNumberString = line.substring(start: 6, length: 5).trimmingCharacters(in: .whitespaces)
                let name = line.substring(start: 12, length: 4).trimmingCharacters(in: .whitespaces)
                let xString = line.substring(start: 30, length: 8).trimmingCharacters(in: .whitespaces)
                let yString = line.substring(start: 38, length: 8).trimmingCharacters(in: .whitespaces)
                let zString = line.substring(start: 46, length: 8).trimmingCharacters(in: .whitespaces)
                let element = line.substring(start: 76, length: 2).trimmingCharacters(in: .whitespaces)

                if let serialNumber = Int(serialNumberString),
                   let x = Float(xString),
                   let y = Float(yString),
                   let z = Float(zString) {
                    let position = SCNVector3(x, y, z)
                    let atom = Atom(serialNumber: serialNumber, name: name, element: element, position: position)
                    atoms.append(atom)
                }
            } else if line.starts(with: "CONECT") {
                let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if tokens.count >= 3 {
                    if let atom1Serial = Int(tokens[1]) {
                        for i in 2..<tokens.count {
                            if let atom2Serial = Int(tokens[i]) {
                                let bond = Bond(atom1Serial: atom1Serial, atom2Serial: atom2Serial)
                                bonds.append(bond)
                            }
                        }
                    }
                }
            }
        }

        return (atoms, bonds)
    }

    class Coordinator: NSObject, SCNSceneRendererDelegate {
        var parent: MoleculeSceneView
        var infoLabel: UILabel?
        weak var scnView: SCNView?

        var initialFieldOfView: CGFloat = 60.0

        init(_ parent: MoleculeSceneView) {
            self.parent = parent
        }

        @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            guard let scnView = scnView else { return }
            let point = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(point, options: [:])
            if let result = hitResults.first, let element = result.node.name {
                showInfoLabel(text: element, at: point, in: scnView)
            } else {
                hideInfoLabel()
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let scnView = scnView,
                  let cameraNode = scnView.pointOfView,
                  let camera = cameraNode.camera else { return }

            if gesture.state == .began {
                initialFieldOfView = camera.fieldOfView
            } else if gesture.state == .changed {
                // On ajuste le fieldOfView de la caméra inversément proportionnel au pinch
                camera.fieldOfView = initialFieldOfView / gesture.scale
            }
        }

        func showInfoLabel(text: String, at point: CGPoint, in scnView: SCNView) {
            if infoLabel == nil {
                infoLabel = UILabel()
                infoLabel?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                infoLabel?.textColor = UIColor.white
                infoLabel?.font = UIFont.systemFont(ofSize: 14)
                infoLabel?.textAlignment = .center
                infoLabel?.layer.cornerRadius = 5
                infoLabel?.layer.masksToBounds = true
            }
            infoLabel?.text = " \(text) "
            infoLabel?.sizeToFit()
            infoLabel?.center = CGPoint(x: point.x, y: point.y - 30)
            if let label = infoLabel, label.superview == nil {
                scnView.addSubview(label)
            }
        }

        func hideInfoLabel() {
            infoLabel?.removeFromSuperview()
        }

        func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
            // Cette méthode est appelée lorsque la scène est rendue.
            print("[MoleculeSceneView.Coordinator] didRenderScene appelé, on va passer sceneIsReady à true")
            DispatchQueue.main.async {
                self.parent.sceneIsReady = true
                print("[MoleculeSceneView.Coordinator] sceneIsReady = true")
            }
            // Remove the delegate to avoid unnecessary calls
            scnView?.delegate = nil
        }
    }
}
