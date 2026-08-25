import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let supabaseURL = URL(string: urlString),
            supabaseURL.scheme == "https",
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !anonKey.isEmpty
        else {
            fatalError("Configure SUPABASE_URL and SUPABASE_ANON_KEY in the app target before using Supabase.")
        }

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: anonKey)
    }
}
