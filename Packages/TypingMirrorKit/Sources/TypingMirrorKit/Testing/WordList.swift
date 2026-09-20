import Foundation

/// Prompt vocabulary for the typing test.
///
/// Common English words only. Because the corpus ships with the app, the test can
/// report which words you hesitate on without ever storing anything you wrote.
public enum WordList {
    public static let common: [String] = """
    the be to of and a in that have I it for not on with he as you do at this but
    his by from they we say her she or an will my one all would there their what so
    up out if about who get which go me when make can like time no just him know
    take people into year your good some could them see other than then now look
    only come its over think also back after use two how our work first well way
    even new want because any these give day most us man find here thing tell very
    life still hand old around small every large need feel high place great little
    world own under last night open next write same start might never while house
      point where much before right through mean keep student group country problem
    turn begin seem help talk word early hold state become book water without
    against during number away again off went white children begin got walk example
    ease paper often always music those both mark often letter until mile river car
    feet care second carry took rain eat room friend began idea fish mountain north
    once base hear horse cut sure watch color face wood main enough plain girl usual
    young ready above ever red list though feel talk bird soon body dog family
    direct pose leave song measure door product black short numeral class wind
    question happen complete ship area half rock order fire south piece told knew
    pass since top whole king street inch multiply nothing course stay wheel full
    force blue object decide surface deep moon island foot system busy test record
    boat common gold possible plane stead dry wonder laugh thousand ago ran check
    game shape equate hot miss brought heat snow tire bring yes distant fill east
    paint language among
    """
        .split(whereSeparator: \.isWhitespace)
        .map(String.init)

    /// A reproducible prompt of `count` words.
    public static func prompt(count: Int, seed: UInt64) -> [String] {
        var rng = SplitMix64(seed: seed)
        return (0..<count).map { _ in
            common[Int(rng.next() % UInt64(common.count))]
        }
    }
}
