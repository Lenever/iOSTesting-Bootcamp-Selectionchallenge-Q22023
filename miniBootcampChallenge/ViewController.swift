//
//  ViewController.swift
//  miniBootcampChallenge
//

import UIKit

class ViewController: UICollectionViewController {

  private struct Constants {
    static let title = "Mini Bootcamp Challenge"
    static let cellID = "imageCell"
    static let cellSpacing: CGFloat = 1
    static let columns: CGFloat = 3
    static var cellSize: CGFloat?
  }

  private lazy var urls: [URL] = URLProvider.urls
  let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
  let fileManager = FileManager.default
  var documentsDirectory: URL?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = Constants.title

    self.view.addSubview(activityView)
    activityView.hidesWhenStopped = true
    activityView.center = self.view.center
    activityView.startAnimating()

    // For the second function
    self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    if let documentsDirectory = self.documentsDirectory {
      downloadImages(urls: urls, fileUrl: documentsDirectory) {
        DispatchQueue.main.async {
          self.activityView.stopAnimating()
          self.collectionView.reloadData()
        }
      }
    }
  }
}


// TODO: 1.- Implement a function that allows the app downloading the images without freezing the UI or causing it to work unexpected way
func fetchImage(url: URL, completion: @escaping (UIImage?) -> Void) {
  URLSession.shared.dataTask(with: url) { data, response, error in
    if let data = data, let image = UIImage(data: data) {
      DispatchQueue.main.async {
        completion(image)
      }
    } else {
      completion(nil)
    }
  }.resume()
}

// TODO: 2.- Implement a function that allows to fill the collection view only when all photos have been downloaded, adding an animation for waiting the completion of the task.
func downloadImages(urls: [URL], fileUrl: URL, completion: @escaping () -> Void) {
  // Create a DispatchGroup to keep track of when all downloads are complete
  let group = DispatchGroup()

  for (index, url) in urls.enumerated() {
    group.enter()

    URLSession.shared.dataTask(with: url) { (data, response, error) in
      defer { group.leave() }

      if let error = error {
        print("Error downloading image from \(url): \(error)")
        return
      }

      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        print("Invalid response when downloading image from \(url)")
        return
      }

      guard let data = data else {
        print("No data when downloading image from \(url)")
        return
      }

      let fileName = "\(index).jpg"
      let fileURL = fileUrl.appendingPathComponent(fileName)

      do {
        try data.write(to: fileURL)
        print("Downloaded and saved image to \(fileURL)")
      } catch {
        print("Error saving image to file: \(error)")
      }
    }.resume()
  }

  // Notify the completion handler when all downloads are complete
  group.notify(queue: DispatchQueue.main) {
    completion()
  }
}



// MARK: - UICollectionView DataSource, Delegate
extension ViewController {
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    urls.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath) as? ImageCell else { return UICollectionViewCell() }

    let url = urls[indexPath.row]

     // For the first function
//    fetchImage(url: url) { image in
//    self.activityView.stopAnimating()
//      cell.display(image)
//    }

    // For the second function
    let fileName = "\(indexPath.row).jpg"
    if let fileURL = documentsDirectory?.appendingPathComponent(fileName),
        let image = UIImage(contentsOfFile: fileURL.path) {
      cell.display(image)
    }

    return cell
  }
}


// MARK: - UICollectionView FlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if Constants.cellSize == nil {
      let layout = collectionViewLayout as! UICollectionViewFlowLayout
      let emptySpace = layout.sectionInset.left + layout.sectionInset.right + (Constants.columns * Constants.cellSpacing - 1)
      Constants.cellSize = (view.frame.size.width - emptySpace) / Constants.columns
    }
    return CGSize(width: Constants.cellSize!, height: Constants.cellSize!)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    Constants.cellSpacing
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    Constants.cellSpacing
  }
}
