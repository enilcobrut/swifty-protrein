import SwiftUI

struct ProteinListView: View {
    @State private var ligands: [String] = []
    @State private var filteredLigands: [String] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false
    @State private var downloadedProteins: [String: String] = [:]
    @State private var showProteinData: Bool = false
    @State private var selectedProteinData: String = ""
    @State private var selectedLigandId: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Barre de recherche
                TextField("Rechercher un ligand", text: $searchQuery)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .onChange(of: searchQuery) {
                        filterLigands()
                    }

                // Liste des ligands
                List {
                    ForEach(filteredLigands, id: \.self) { ligandId in
                        HStack {
                            Text(ligandId)
                            Spacer()
                            Button(action: {
                                if downloadedProteins.keys.contains(ligandId) {
                                    selectedProteinData = downloadedProteins[ligandId] ?? ""
                                    selectedLigandId = ligandId
                                    showProteinData = true
                                } else {
                                    fetchPdbFile(for: ligandId)
                                }
                            }) {
                                Image(systemName: downloadedProteins.keys.contains(ligandId) ? "folder.fill" : "icloud.and.arrow.down")
                                    .foregroundColor(downloadedProteins.keys.contains(ligandId) ? .green : .blue)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()

                // Indicateur de chargement
                if isLoading {
                    ProgressView("Téléchargement...")
                        .padding()
                }

                // Texte en bas de la vue
                Text("Réalisé par Sasso Stark et Celiniya")
                    .padding()
                    .font(.footnote)
            }
            .navigationTitle("Liste des Protéines")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadLigands)
            .sheet(isPresented: $showProteinData) {
                ProteinDataView(ligandId: selectedLigandId, pdbData: selectedProteinData)
            }
        }
    }

    // Fonction pour charger les ligands depuis le fichier local
    func loadLigands() {
        if let path = Bundle.main.path(forResource: "ligands", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path)
                ligands = data.components(separatedBy: "\n").filter { !$0.isEmpty }
                filteredLigands = ligands
            } catch {
                print("Erreur lors du chargement des ligands : \(error)")
            }
        } else {
            print("Fichier ligands.txt introuvable")
        }
    }

    // Fonction pour filtrer les ligands en fonction de la recherche
    func filterLigands() {
        if searchQuery.isEmpty {
            filteredLigands = ligands
        } else {
            filteredLigands = ligands.filter { $0.lowercased().contains(searchQuery.lowercased()) }
        }
    }

    // Fonction pour télécharger le fichier PDB depuis l'API
    func fetchPdbFile(for ligandId: String) {
        isLoading = true
        let ligandIdUpper = ligandId.uppercased()
        guard let charCode = ligandIdUpper.first else {
            print("LigandId invalide")
            isLoading = false
            return
        }
        let urlString = "https://files.rcsb.org/ligands/\(charCode)/\(ligandIdUpper)/\(ligandIdUpper)_ideal.pdb"
        guard let url = URL(string: urlString) else {
            print("URL invalide")
            isLoading = false
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("Erreur lors du téléchargement : \(error.localizedDescription)")
                    return
                }

                if let data = data, let pdbData = String(data: data, encoding: .utf8) {
                    downloadedProteins[ligandId] = pdbData
                    selectedProteinData = pdbData
                    selectedLigandId = ligandId
                    showProteinData = true
                } else {
                    print("Données invalides reçues")
                }
            }
        }
        task.resume()
    }
}

struct ProteinListView_Previews: PreviewProvider {
    static var previews: some View {
        ProteinListView()
    }
}
