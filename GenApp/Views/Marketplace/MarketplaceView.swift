//
//  MarketplaceView.swift
//  GenApp
//
//  Created by Simy's MacBook Pro on 11/17/25.
//

import SwiftUI

struct MarketplaceView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @ObservedObject var theme: AppTheme
    @State private var showDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(theme.secondaryTextColor)
                        TextField("Search...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(theme.textColor)
                    }
                    .padding()
                    .background(theme.secondaryBackground)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: viewModel.selectedCategory == category,
                                    theme: theme
                                ) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Items grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(viewModel.filteredItems) { item in
                                MarketplaceItemCard(item: item, theme: theme)
                                    .onTapGesture {
                                        viewModel.selectedItem = item
                                        viewModel.loadReviews(for: item.id)
                                        showDetail = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Marketplace")
            .sheet(isPresented: $showDetail) {
                if let item = viewModel.selectedItem {
                    MarketplaceDetailView(item: item, viewModel: viewModel, theme: theme)
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    @ObservedObject var theme: AppTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            theme.primaryColor
                        } else {
                            theme.secondaryBackground
                        }
                    }
                )
                .cornerRadius(20)
        }
    }
}

struct MarketplaceItemCard: View {
    let item: MarketplaceItem
    @ObservedObject var theme: AppTheme
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                theme.primaryColor.opacity(0.3),
                                theme.primaryColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)
                
                if item.isFree {
                    VStack {
                        HStack {
                            Spacer()
                            Text("FREE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(2)
                
                HStack {
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", item.rating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textColor)
                    }
                    
                    Spacer()
                    
                    // Price
                    if !item.isFree {
                        Text("$\(String(format: "%.2f", item.price))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(theme.primaryColor)
                    }
                }
                
                Text("by \(item.creatorName)")
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding()
        .background(theme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct MarketplaceDetailView: View {
    let item: MarketplaceItem
    @ObservedObject var viewModel: MarketplaceViewModel
    @ObservedObject var theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    @State private var showReviewSheet = false
    @State private var rating = 5
    @State private var reviewComment = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header image
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        theme.primaryColor.opacity(0.4),
                                        theme.primaryColor.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 200)
                        
                        if item.isFree {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("FREE")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(theme.textColor)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", item.rating))
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("(\(item.reviewCount))")
                                        .font(.system(size: 14))
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                if !item.isFree {
                                    Text("$\(String(format: "%.2f", item.price))")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            
                            Text("by \(item.creatorName)")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(theme.textColor)
                            
                            Text(item.description)
                                .font(.system(size: 16))
                                .foregroundColor(theme.textColor)
                        }
                        .padding(.horizontal)
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            if item.hasTrial {
                                Button(action: {
                                    // Start trial
                                }) {
                                    Text("Try Free")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(theme.primaryColor)
                                        .cornerRadius(15)
                                }
                            }
                            
                            Button(action: {
                                viewModel.downloadItem(item)
                            }) {
                                Text(item.isFree ? "Download" : "Purchase")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [theme.primaryColor, theme.primaryColor.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Reviews section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reviews")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(theme.textColor)
                                
                                Spacer()
                                
                                Button(action: {
                                    showReviewSheet = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(theme.primaryColor)
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.reviews.isEmpty {
                                Text("No reviews yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.secondaryTextColor)
                                    .padding(.horizontal)
                            } else {
                                ForEach(viewModel.reviews) { review in
                                    ReviewRow(review: review, theme: theme)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(theme.backgroundColor)
            .navigationTitle("Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showReviewSheet) {
                ReviewSheet(item: item, viewModel: viewModel, theme: theme)
            }
        }
    }
}

struct ReviewRow: View {
    let review: Review
    @ObservedObject var theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.userName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(index <= review.rating ? .yellow : theme.secondaryTextColor)
                    }
                }
            }
            
            Text(review.comment)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
        }
        .padding()
        .background(theme.secondaryBackground)
        .cornerRadius(12)
    }
}

struct ReviewSheet: View {
    let item: MarketplaceItem
    @ObservedObject var viewModel: MarketplaceViewModel
    @ObservedObject var theme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    @State private var rating = 5
    @State private var comment = ""
    @State private var userName = "You"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Rating") {
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Button(action: {
                                rating = index
                            }) {
                                Image(systemName: index <= rating ? "star.fill" : "star")
                                    .font(.system(size: 30))
                                    .foregroundColor(index <= rating ? .yellow : theme.secondaryTextColor)
                            }
                        }
                    }
                }
                
                Section("Review") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Write Review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        let review = Review(
                            itemId: item.id,
                            userId: "current_user",
                            userName: userName,
                            rating: rating,
                            comment: comment
                        )
                        viewModel.addReview(review)
                        dismiss()
                    }
                    .disabled(comment.isEmpty)
                }
            }
        }
    }
}

