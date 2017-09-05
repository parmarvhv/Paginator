//
//  PaginationManager.swift
//  Paginator
//
//  Created by Vaibhav Parmar on 30/08/17.
//  Copyright © 2017 Vaibhav Parmar. All rights reserved.
//

import UIKit
import PullToRefresh

public protocol PaginationManagerDelegate {
	func refreshAll(completion: @escaping (_ hasMoreData: Bool) -> Void)
	func loadMore(completion: @escaping (_ hasMoreData: Bool) -> Void)
}


public class PaginationManager: NSObject {
	fileprivate weak var scrollView: UIScrollView?
	fileprivate var refreshControl: UIRefreshControl?
	fileprivate var bottomLoader: UIView?
	fileprivate var isObservingKeyPath: Bool = false
	var contentView: ContentView?
	var refreshView: RefreshView?
	
	var delegate: PaginationManagerDelegate?
	
	var showPullToRefresh: Bool {
		didSet {
			self.setupPullToRefresh()
		}
	}
	var isLoading = false
	var hasMoreDataToLoad = true
	
	init(scrollView: UIScrollView, showPullToRefresh: Bool = true) {
		self.scrollView = scrollView
		self.showPullToRefresh = showPullToRefresh
		super.init()
		self.setupPullToRefresh()
	}
	
	deinit {
		self.removeScrollViewOffsetObserver()
	}
	
	func load(completion: @escaping () -> Void) {
		self.refresh {
			completion()
		}
	}
}

extension PaginationManager {
	
	func setupPullToRefresh() {
		if !self.showPullToRefresh {
			self.removeRefreshControl()
			return
		}
		
		if self.showPullToRefresh && self.contentView == nil {
			self.addRefreshControl()
			return
		}
		
		if refreshView == nil {
			guard let contentView = self.contentView else { return }
			refreshView = RefreshView(scrollView: self.scrollView, delegate: self, contentView: contentView)
		}
	}
	
	fileprivate func addRefreshControl() {
		self.refreshControl = UIRefreshControl()
		self.scrollView?.addSubview(self.refreshControl!)
		self.refreshControl?.addTarget(
			self,
			action: #selector(PaginationManager.handleRefresh),
			for: .valueChanged)
	}
	
	fileprivate func removeRefreshControl() {
		self.refreshControl?.removeTarget(
			self,
			action: #selector(PaginationManager.handleRefresh),
			for: .valueChanged)
		self.refreshControl?.removeFromSuperview()
		self.refreshControl = nil
	}
	
	@objc fileprivate func handleRefresh() {
		if self.isLoading {
			self.refreshControl?.endRefreshing()
			return
		}
		self.isLoading = true
		self.delegate?.refreshAll(completion: { [weak self] hasMoreData in
			guard let this = self else { return }
			this.isLoading = false
			this.hasMoreDataToLoad = hasMoreData
			this.refreshControl?.endRefreshing()
		})
	}
	
	fileprivate func refresh(completion: @escaping () -> Void) {
		if self.isLoading {
			self.refreshControl?.endRefreshing()
			return
		}
		self.isLoading = true
		self.delegate?.refreshAll(completion: { [weak self] hasMoreData in
			guard let this = self else { return }
			this.isLoading = false
			this.hasMoreDataToLoad = hasMoreData
			if hasMoreData {
				this.addScrollViewOffsetObserver()
				this.addBottomLoader()
			}
			this.refreshControl?.endRefreshing()
			completion()
		})
	}
}

extension PaginationManager {
	fileprivate func addBottomLoader() {
		guard let scrollView = self.scrollView else { return }
		let view = UIView()
		view.frame.size = CGSize(width: scrollView.frame.width, height: 60)
		view.frame.origin = CGPoint(x: 0, y: scrollView.contentSize.height)
		view.backgroundColor = UIColor.clear
		let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
		activity.frame = view.bounds
		activity.startAnimating()
		view.addSubview(activity)
		self.bottomLoader = view
		scrollView.contentInset.bottom = view.frame.height
	}
	
	fileprivate func showBottomLoader() {
		guard let scrollView = self.scrollView, let loader = self.bottomLoader else { return }
		scrollView.addSubview(loader)
	}
	
	fileprivate func hideBottomLoader() {
		self.bottomLoader?.removeFromSuperview()
	}
	
	fileprivate func removeBottomLoader() {
		self.bottomLoader?.removeFromSuperview()
		self.scrollView?.contentInset.bottom = 0
	}
	
	func addScrollViewOffsetObserver() {
		if self.isObservingKeyPath { return }
		self.scrollView?.addObserver(
			self,
			forKeyPath: "contentOffset",
			options: [.new],
			context: nil)
		self.isObservingKeyPath = true
	}
	
	func removeScrollViewOffsetObserver() {
		if self.isObservingKeyPath {
			self.scrollView?.removeObserver(self, forKeyPath: "contentOffset")
		}
		self.isObservingKeyPath = false
	}
	
	override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let object = object as? UIScrollView, let keyPath = keyPath, let newValue = change?[.newKey] as? CGPoint else { return }
		if object == self.scrollView && keyPath == "contentOffset" {
			self.setContentOffSet(newValue)
		}
	}
	
	fileprivate func setContentOffSet(_ offset: CGPoint) {
		guard let scrollView = self.scrollView else { return }
		self.bottomLoader?.frame.origin.y = scrollView.contentSize.height
		if !scrollView.isDragging && !scrollView.isDecelerating  { return }
		if self.isLoading || !self.hasMoreDataToLoad { return }
		let offsetY = offset.y
		if offsetY >= scrollView.contentSize.height - scrollView.frame.size.height {
			self.isLoading = true
			self.showBottomLoader()
			self.delegate?.loadMore(completion: { [weak self] hasMoreData in
				guard let this = self else { return }
				this.hideBottomLoader()
				this.isLoading = false
				this.hasMoreDataToLoad = hasMoreData
				if !hasMoreData {
					this.removeBottomLoader()
					this.removeScrollViewOffsetObserver()
				}
			})
		}
	}
}

extension PaginationManager: RefreshViewDelegate {
	
	public func refreshViewShouldStartRefreshing(_ refreshView: RefreshView) -> Bool {
		return self.showPullToRefresh && self.contentView != nil
	}
	
	public func refreshViewDidStartRefreshing(_ refreshView: RefreshView) {
		handleRefresh()
	}
	
	public func refreshViewDidFinishRefreshing(_ refreshView: RefreshView) {
		
	}
	
	public func lastUpdatedAtForRefreshView(_ refreshView: RefreshView) -> Date? {
		return Date()
	}
	
	public func refreshView(_ refreshView: RefreshView, didUpdateContentInset contentInset: UIEdgeInsets) {
		
	}
	
	public func refreshView(_ refreshView: RefreshView, willTransitionTo to: RefreshView.State, from: RefreshView.State, animated: Bool) {
		
	}
	
	public func refreshView(_ refreshView: RefreshView, didTransitionTo to: RefreshView.State, from: RefreshView.State, animated: Bool) {
		
	}
}
