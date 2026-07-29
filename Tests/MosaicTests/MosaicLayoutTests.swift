@_spi(MosaicTesting) import MosaicCore
import Testing
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
struct MosaicLayoutTests {
    @Test
    func layoutHelpersExposeConfiguredSections() {
        let grid = MosaicLayout.grid(
            columns: 3,
            spacing: 9,
            interItemSpacing: 4,
            insets: .init(top: 1, leading: 2, bottom: 3, trailing: 4),
            itemHeight: .absolute(80)
        ).resolve(.init(width: 360, height: 600))
        assertInsets(grid.contentInsets, top: 1, leading: 2, bottom: 3, trailing: 4)
        #expect(grid.interGroupSpacing == 9)

        let adaptive = MosaicLayout.adaptiveGrid(
            minItemWidth: 120,
            maximumColumns: 2,
            spacing: 10,
            interItemSpacing: 5,
            insets: .init(top: 5, leading: 6, bottom: 7, trailing: 8),
            itemHeight: .absolute(90)
        ).resolve(.init(width: 520, height: 600))
        assertInsets(adaptive.contentInsets, top: 5, leading: 6, bottom: 7, trailing: 8)
        #expect(adaptive.interGroupSpacing == 10)

        let carousel = MosaicLayout.carousel(
            itemHeight: .absolute(160),
            spacing: 14,
            insets: .init(top: 10, leading: 11, bottom: 12, trailing: 13),
            behavior: .continuous
        ).resolve(.init(width: 320, height: 600))
        assertInsets(carousel.contentInsets, top: 10, leading: 11, bottom: 12, trailing: 13)
        #expect(carousel.interGroupSpacing == 14)
        #expect(carousel.orthogonalScrollingBehavior == .continuous)

        let waterfall = MosaicLayout.waterfall(
            columns: 4,
            spacing: 6,
            interItemSpacing: 3,
            insets: .init(top: 2, leading: 3, bottom: 4, trailing: 5),
            estimatedHeight: 70
        ).resolve(.init(width: 320, height: 600))
        assertInsets(waterfall.contentInsets, top: 2, leading: 3, bottom: 4, trailing: 5)
        #expect(waterfall.interGroupSpacing == 6)

        assertListLayoutsResolve()

        let rawSection = NSCollectionLayoutSection(group: .vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
            subitems: [
                NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
                ),
            ]
        ))
        rawSection.interGroupSpacing = 17

        let wrapped = MosaicLayout(rawSection).resolve(.init(width: 320, height: 600))
        #expect(wrapped.interGroupSpacing == 17)
    }

    @Test
    func customLayoutsResolveWithProvidedInputs() {
        var capturedSize = CGSize.zero
        let custom = MosaicLayout.custom { size in
            capturedSize = size
            let section = MosaicDefaultLayout.list()
            section.interGroupSpacing = size.width
            return section
        }

        let resolvedCustom = custom.resolve(.init(width: 412, height: 800))
        #expect(capturedSize == CGSize(width: 412, height: 800))
        #expect(resolvedCustom.interGroupSpacing == 412)
    }

    @Test
    func compositionalLayoutDSLBuildsSectionsAndAppliesModifiers() {
        let layout = MosaicLayout.section {
            MosaicLayoutGroup.horizontal(
                height: .absolute(96),
                repeating: MosaicLayoutItem(
                    width: .fractionalWidth(0.5),
                    height: .fractionalHeight(1.0)
                ),
                count: 2,
                interItemSpacing: 7
            )
        }
        .contentInsets(.init(top: 2, leading: 4, bottom: 6, trailing: 8))
        .interGroupSpacing(11)
        .orthogonalScrollingBehavior(.continuous)

        let resolved = layout.resolve(.init(width: 320, height: 600))

        assertInsets(resolved.contentInsets, top: 2, leading: 4, bottom: 6, trailing: 8)
        #expect(resolved.interGroupSpacing == 11)
        #expect(resolved.orthogonalScrollingBehavior == .continuous)
    }

    @Test
    func sectionHeaderAndFooterLayoutModifiersInstallBoundaryItems() {
        let resolved = MosaicLayout.grid(columns: 1)
            .sectionHeader(height: .absolute(32), pinToVisibleBounds: true)
            .sectionFooter(height: .absolute(24))
            .resolve(.init(width: 320, height: 600))

        #expect(resolved.boundarySupplementaryItems.count == 2)
        #expect(resolved.boundarySupplementaryItems.map(\.elementKind) == [
            MosaicCollectionView.elementKindSectionHeader,
            MosaicCollectionView.elementKindSectionFooter,
        ])
        #expect(resolved.boundarySupplementaryItems.first?.pinToVisibleBounds == true)
    }

    @Test
    func decoratedLayoutsAddBackgroundDecorationItems() {
        let decoration = MosaicDecorationRegistration(
            elementKind: "test-background",
            viewClass: MosaicReusableView.self
        )

        let decoratedList = MosaicLayout.list()
            .decorated(by: decoration)
            .resolve(.init(width: 320, height: 600))

        #expect(decoratedList.decorationItems.count == 1)

        let wrappedSection = NSCollectionLayoutSection(group: .vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
            subitems: [
                NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
                ),
            ]
        ))

        let decoratedWrappedSection = MosaicLayout(wrappedSection)
            .decorated(by: decoration)
            .resolve(.init(width: 320, height: 600))

        #expect(decoratedWrappedSection.decorationItems.count == 1)
    }

    @Test
    func listSwipeConfigurationUsesLiveItemProvider() {
        let staleItem = MosaicItem(
            id: "stale",
            cellType: MosaicListCell.self,
            value: "stale",
            contentHash: 1,
            configure: { _, _ in }
        )
        .leadingSwipeActionsConfiguration { value in
            let action = MosaicSwipeAction(style: .normal, title: value as? String) { completion in
                completion(true)
            }
            return MosaicSwipeActionsConfiguration(actions: [action])
        }

        let freshItem = MosaicItem(
            id: "fresh",
            cellType: MosaicListCell.self,
            value: "fresh",
            contentHash: 2,
            configure: { _, _ in }
        )
        .leadingSwipeActionsConfiguration { value in
            let action = MosaicSwipeAction(style: .normal, title: value as? String) { completion in
                completion(true)
            }
            return MosaicSwipeActionsConfiguration(actions: [action])
        }

        let configuration = MosaicDefaultLayout.swipeActionsConfiguration(
            at: IndexPath(item: 0, section: 0),
            itemProvider: { _ in
                _ = staleItem
                return freshItem
            },
            deleteHandler: { _, completion in
                completion()
            },
            keyPath: \.leadingSwipeActionsConfiguration
        )

        #expect(configuration?.actions.first?.title == "fresh")
    }

    @Test
    func decoratedWrappedSectionDoesNotAccumulateDecorationItemsAcrossResolves() {
        let decoration = MosaicDecorationRegistration(
            elementKind: "test-background",
            viewClass: MosaicReusableView.self
        )

        let wrappedSection = NSCollectionLayoutSection(group: .vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
            subitems: [
                NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
                ),
            ]
        ))

        let decoratedLayout = MosaicLayout(wrappedSection)
            .decorated(by: decoration)

        let firstResolve = decoratedLayout.resolve(.init(width: 320, height: 600))
        let secondResolve = decoratedLayout.resolve(.init(width: 320, height: 600))

        #expect(firstResolve.decorationItems.count == 1)
        #expect(secondResolve.decorationItems.count == 1)
    }

    @Test
    func decoratedLayoutDeduplicatesExistingManagedDecorationItems() {
        let decoration = MosaicDecorationRegistration(
            elementKind: "test-background",
            viewClass: MosaicReusableView.self
        )

        let wrappedSection = NSCollectionLayoutSection(group: .vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44)),
            subitems: [
                NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
                ),
            ]
        ))
        wrappedSection.decorationItems = [
            .background(elementKind: "test-background"),
            .background(elementKind: "test-background"),
        ]

        let resolvedSection = MosaicLayout(wrappedSection)
            .decorated(by: decoration)
            .resolve(.init(width: 320, height: 600))

        #expect(resolvedSection.decorationItems.count == 1)
        #expect(resolvedSection.decorationItems.first?.elementKind == "test-background")
    }
}

@MainActor
private func assertListLayoutsResolve() {
    let list = MosaicLayout.list().resolve(.init(width: 320, height: 600))
    #expect(list.interGroupSpacing == 0)

    for style in MosaicListStyle.allCases {
        let resolved = MosaicLayout.list(style: style).resolve(.init(width: 320, height: 600))
        #expect(resolved.interGroupSpacing == 0)
    }
}
